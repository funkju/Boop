//
//  BufferRunner.swift
//  Boop
//
//  In-buffer REPL: evaluate the buffer as JavaScript (in-process
//  JavaScriptCore) or PHP (local php binary) and splice the result back in
//  as a trailing "// =>" comment block. Both languages treat // as a
//  comment, so the buffer stays valid, re-runnable source.
//

import Foundation
import JavaScriptCore

enum BufferRunner {

    enum RunError: Error, LocalizedError {
        case failed(String)
        case phpMissing
        case timeout

        var errorDescription: String? {
            switch self {
            case .failed(let message): return message
            case .phpMissing: return "No php binary found (looked in Homebrew and /usr/bin)"
            case .timeout: return "PHP timed out after 5 seconds"
            }
        }
    }

    // MARK: - Result block

    static let resultPrefix = "// => "
    /// Errors are a valid outcome of a run — they land in the buffer too,
    /// just visibly marked as errors.
    static let errorPrefix = "// !! "
    static let continuationPrefix = "//    "

    static func formatResultBlock(_ output: String) -> String {
        block(output, prefix: resultPrefix)
    }

    static func formatErrorBlock(_ message: String) -> String {
        block(message, prefix: errorPrefix)
    }

    private static func block(_ output: String, prefix: String) -> String {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
        guard let first = lines.first else { return prefix.trimmingCharacters(in: .whitespaces) }
        var block = prefix + first
        for line in lines.dropFirst() {
            block += "\n" + continuationPrefix + line
        }
        return block
    }

    /// Removes a trailing result block (plus surrounding blank lines) so a
    /// re-run replaces the previous answer instead of stacking a new one.
    /// Comments elsewhere in the buffer are untouched — only a block at the
    /// very end whose first line is "// => " counts.
    static func stripTrailingResultBlock(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var last = lines.count - 1
        while last >= 0, lines[last].trimmingCharacters(in: .whitespaces).isEmpty { last -= 1 }
        var first = last
        while first >= 0, lines[first].hasPrefix(continuationPrefix) { first -= 1 }
        guard first >= 0,
              lines[first].hasPrefix(resultPrefix) || lines[first].hasPrefix(errorPrefix)
        else { return text }
        lines.removeSubrange(first...)
        while let trailing = lines.last, trailing.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - JavaScript

    static func runJavaScript(_ code: String) -> Result<String, RunError> {
        guard let context = JSContext() else {
            return .failure(.failed("Could not create a JavaScript context"))
        }

        var logs: [String] = []
        let capture: @convention(block) (String) -> Void = { logs.append($0) }
        context.setObject(capture, forKeyedSubscript: "__boopLog" as NSString)
        context.evaluateScript("""
            function __boopFormat(v) {
                if (typeof v === "string") return v;
                if (typeof v === "function") return String(v);
                try {
                    var s = JSON.stringify(v, null, 2);
                    if (s !== undefined) return s;
                } catch (e) {}
                return String(v);
            }
            var console = (function () {
                function emit() {
                    __boopLog(Array.prototype.map.call(arguments, __boopFormat).join(" "));
                }
                return { log: emit, info: emit, warn: emit, error: emit, debug: emit };
            })();
            """)

        var exception: String?
        context.exceptionHandler = { _, value in
            exception = value?.toString() ?? "Unknown JavaScript error"
        }

        let value = context.evaluateScript(code)
        if let exception {
            return .failure(.failed(exception))
        }

        var parts = logs
        if let value, !value.isUndefined {
            let formatted = context.objectForKeyedSubscript("__boopFormat")?
                .call(withArguments: [value])?.toString()
            parts.append(formatted ?? "undefined")
        }
        return .success(parts.isEmpty ? "undefined" : parts.joined(separator: "\n"))
    }

    // MARK: - PHP

    static let phpCandidates = [
        "/opt/homebrew/bin/php",
        "/usr/local/bin/php",
        "/usr/bin/php",
    ]

    static var phpPath: String? {
        phpCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func runPHP(_ code: String) -> Result<String, RunError> {
        guard let php = phpPath else { return .failure(.phpMissing) }

        // Bare statements are the common case in a scratch buffer.
        let source = code.contains("<?") ? code : "<?php\n" + code

        let process = Process()
        process.executableURL = URL(fileURLWithPath: php)
        let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return .failure(.failed(error.localizedDescription))
        }

        stdin.fileHandleForWriting.write(Data(source.utf8))
        stdin.fileHandleForWriting.closeFile()

        // Watchdog: an accidental infinite loop gets SIGTERMed, not hung on.
        let killer = DispatchWorkItem { process.terminate() }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: killer)

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        killer.cancel()

        if process.terminationReason == .uncaughtSignal, process.terminationStatus == SIGTERM {
            return .failure(.timeout)
        }

        let out = String(decoding: outData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let err = String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            return .failure(.failed(err.isEmpty ? (out.isEmpty ? "PHP exited with status \(process.terminationStatus)" : out) : err))
        }

        // Warnings land on stderr even on success — keep them visible.
        let combined = [out, err].filter { !$0.isEmpty }.joined(separator: "\n")
        return .success(combined.isEmpty ? "(no output)" : combined)
    }
}
