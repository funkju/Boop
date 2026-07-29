//
//  PlainTextCopy.swift
//  Boop
//
//  The editor's copy(_:) puts syntax-highlighted attributed strings on the
//  pasteboard, so pasting into rich-text targets drags Boop's font and
//  colors along. Boop is a text utility — copy should always be plain.
//  TextView.copy(_:) is @objc open and the controller instantiates the
//  view itself, so the override happens by swapping implementations.
//

import AppKit
import CodeEditTextView

enum PlainTextCopy {

    /// Idempotent: the exchange happens once no matter how often this is
    /// referenced (static let initializer).
    static let apply: Void = {
        let copySelector = #selector(TextView.copy(_:) as (TextView) -> (AnyObject) -> Void)
        guard let original = class_getInstanceMethod(TextView.self, copySelector),
              let replacement = class_getInstanceMethod(
                TextView.self, #selector(TextView.boop_plainTextCopy(_:))
              )
        else {
            assertionFailure("Could not install plain-text copy override")
            return
        }
        method_exchangeImplementations(original, replacement)
    }()
}

extension TextView {
    @objc fileprivate func boop_plainTextCopy(_ sender: AnyObject) {
        let text = textStorage.string as NSString
        let strings = (selectionManager?.textSelections ?? [])
            .map(\.range)
            .filter { $0.length > 0 && NSMaxRange($0) <= text.length }
            .sorted { $0.location < $1.location }
            .map { text.substring(with: $0) }
        guard !strings.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(strings.joined(separator: "\n"), forType: .string)
    }
}
