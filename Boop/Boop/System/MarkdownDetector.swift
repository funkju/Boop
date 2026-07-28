//
//  MarkdownDetector.swift
//  Boop
//
//  Content-based markdown sniffing. There is no standard for this — like
//  every editor that does it, we score conventional markdown constructs and
//  require signals from more than one family so a shell script full of
//  "# comments" doesn't read as a document of headings.
//

import Foundation

enum MarkdownDetector {

    /// Per-family score caps so one repeated construct can't win alone.
    private static let caps: [String: Int] = [
        "heading": 6,
        "quote": 4,
        "list": 4,
        "olist": 3,
        "table": 4,
        "rule": 2,
        "link": 6,
        "bold": 4,
        "italic": 2,
        "inlinecode": 3,
        "fence": 6,
    ]

    static func looksLikeMarkdown(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        var scores: [String: Int] = [:]
        var fenceCount = 0
        var inFence = false
        var leadingHeading = false
        var seenContent = false

        for rawLine in text.components(separatedBy: .newlines).prefix(400) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if !seenContent && !line.isEmpty {
                seenContent = true
                // Opening straight with "# Title" is a strong tell; it earns
                // a bonus and a lower acceptance bar below.
                leadingHeading = matches(line, #"^#{1,6} \S"#)
            }

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                fenceCount += 1
                inFence.toggle()
                continue
            }
            // Don't score code inside a fence — bash comments in a fenced
            // block would otherwise count as headings.
            if inFence { continue }

            if matches(line, #"^#{1,6} \S"#) {
                scores["heading", default: 0] += 2
            } else if matches(line, #"^> "#) {
                scores["quote", default: 0] += 2
            } else if matches(line, #"^[-*+] \S"#) {
                scores["list", default: 0] += 1
            } else if matches(line, #"^\d{1,3}[.)] \S"#) {
                scores["olist", default: 0] += 1
            } else if matches(line, #"^\|.+\|$"#) {
                scores["table", default: 0] += 2
            } else if matches(line, #"^(-{3,}|\*{3,}|_{3,})$"#) {
                scores["rule", default: 0] += 1
            }

            if matches(line, #"\[[^\]]+\]\([^)\s]+\)"#) {
                scores["link", default: 0] += 3
            }
            // No __bold__ variant: it matches Python dunders like __init__.
            if matches(line, #"\*\*[^*\n]+\*\*"#) {
                scores["bold", default: 0] += 2
            } else if matches(line, #"\*[A-Za-z][^*\n]*\*"#) {
                scores["italic", default: 0] += 1
            }
            if matches(line, #"`[^`\n]+`"#) {
                scores["inlinecode", default: 0] += 1
            }
        }

        if fenceCount >= 2 {
            scores["fence"] = 3 * (fenceCount / 2)
        }
        if leadingHeading {
            scores["heading", default: 0] += 2
        }

        let total = scores.reduce(0) { sum, entry in
            sum + min(entry.value, caps[entry.key] ?? entry.value)
        }
        let threshold = leadingHeading ? 4 : 6
        return total >= threshold && scores.count >= 2
    }

    private static func matches(_ line: String, _ pattern: String) -> Bool {
        line.range(of: pattern, options: .regularExpression) != nil
    }
}
