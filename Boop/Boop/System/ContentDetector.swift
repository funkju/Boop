//
//  ContentDetector.swift
//  Boop
//
//  Content-based language sniffing for pasted/typed text: JSON, markdown,
//  and PHP. Order matters — markdown runs before the PHP heuristics so a
//  markdown document with ```php fences stays markdown (the markdown
//  detector already ignores fenced content when scoring).
//

import Foundation
import CodeEditLanguages

enum ContentDetector {

    static func detect(_ text: String) -> CodeLanguage? {
        if looksLikeJSON(text) { return .json }
        if MarkdownDetector.looksLikeMarkdown(text) { return .markdown }
        if looksLikePHP(text) { return .php }
        return nil
    }

    // MARK: - JSON

    /// Deliberately lenient: strict JSONSerialization is only a fast
    /// confirm, not a gate, so JS-style object literals (unquoted keys,
    /// trailing commas) still count.
    static func looksLikeJSON(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return false }
        guard let first = trimmed.first, first == "{" || first == "[" else { return false }
        guard let last = trimmed.last, last == "}" || last == "]" else { return false }

        if let data = trimmed.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil {
            return true
        }

        // Sloppy object: some key/value shape inside braces.
        if first == "{" {
            return trimmed.range(of: #"["']?[\w-]+["']?\s*:"#, options: .regularExpression) != nil
        }
        // Sloppy array: needs commas or nested structure, so bracketed prose
        // like "[TODO: fix this]" doesn't count.
        return trimmed.contains(",") || trimmed.contains("{") || trimmed.contains("[", after: 1)
    }

    // MARK: - PHP

    static func looksLikePHP(_ text: String) -> Bool {
        if text.contains("<?php") || text.contains("<?=") { return true }

        var score = 0
        // Bare $var usage is weak on its own (shell has it too — the cap
        // keeps a script full of "$HOME"s under the threshold), but it
        // tips genuinely PHP-shaped snippets over the line.
        score += min(countMatches(text, #"\$[A-Za-z_]\w*"#), 4)
        score += min(countMatches(text, #"\$[A-Za-z_]\w*\s*="#), 3) * 2      // $var = …
        score += min(countMatches(text, #"\$[A-Za-z_]\w*->"#), 3) * 2        // $obj->prop
        score += min(countMatches(text, #"[A-Za-z_]\w*\(\s*\$"#), 2) * 3     // func($var
        score += min(countMatches(text, #"function\s+\w+\s*\([^)\n]*\$"#), 2) * 3
        score += min(countMatches(text, #"foreach\s*\(\s*\$"#), 2) * 3
        score += min(countMatches(text, #"\w::\w"#), 2)                      // Class::method
        return score >= 6
    }

    private static func countMatches(_ text: String, _ pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }
}

private extension String {
    /// Whether `substring` occurs at or after character offset `index`.
    func contains(_ substring: String, after index: Int) -> Bool {
        guard count > index else { return false }
        return dropFirst(index).contains(substring)
    }
}
