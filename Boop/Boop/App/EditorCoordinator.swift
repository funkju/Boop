//
//  EditorCoordinator.swift
//  Boop
//
//  Captures the CodeEdit TextViewController so the script engine can read
//  selections and perform undoable text replacements.
//

import AppKit
import CodeEditSourceEditor
import CodeEditTextView

final class EditorCoordinator: TextViewCoordinator {

    /// Backing storage for the editor; owned here so the document outlives
    /// SwiftUI view updates.
    let textStorage = NSTextStorage()

    private(set) weak var controller: TextViewController?

    /// Fired after every edit; AppModel uses it for markdown detection.
    var onTextChange: (() -> Void)?

    /// TextView.delegate is weak — keep the proxy alive.
    private var quoteSuppressor: QuotePairSuppressor?

    var textView: TextView? {
        controller?.textView
    }

    func prepareCoordinator(controller: TextViewController) {
        self.controller = controller
        _ = PlainTextCopy.apply
        // NSClipView reports itself opaque whenever it draws a background —
        // even a transparent color — which blocks the window's glass
        // material. Stop drawing; the tint lives in ContentView instead.
        controller.scrollView?.drawsBackground = false

        // Boop buffers are prose as often as code: typing don't should not
        // become don''t. Route quote keystrokes around the controller's
        // TextFormation pipeline so no closing quote is auto-inserted.
        let suppressor = QuotePairSuppressor(controller: controller)
        quoteSuppressor = suppressor
        controller.textView.delegate = suppressor
    }

    func textViewDidChangeText(controller: TextViewController) {
        onTextChange?()
    }

    func focus() {
        guard let textView = controller?.textView else { return }
        textView.window?.makeFirstResponder(textView)
    }

    /// Drops first responder off the AppKit text view so SwiftUI focus
    /// (e.g. the palette's search field) can take over.
    func blur() {
        guard let textView = controller?.textView else { return }
        textView.window?.makeFirstResponder(nil)
    }

    func destroy() {
        controller = nil
        quoteSuppressor = nil
    }
}

/// Sits between the TextView and its TextViewController, passing every
/// delegate call through except one case: a typed quote character. Those
/// skip the controller's filter pipeline (which would auto-insert a matching
/// closing quote) and are applied verbatim. Brackets keep their smart
/// pairing.
private final class QuotePairSuppressor: TextViewDelegate {

    private weak var controller: TextViewController?

    init(controller: TextViewController) {
        self.controller = controller
    }

    func textView(_ textView: TextView, willReplaceContentsIn range: NSRange, with string: String) {
        controller?.textView(textView, willReplaceContentsIn: range, with: string)
    }

    func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with string: String) {
        controller?.textView(textView, didReplaceContentsIn: range, with: string)
    }

    func textView(_ textView: TextView, shouldReplaceContentsIn range: NSRange, with string: String) -> Bool {
        if string == "\"" || string == "'" || string == "`" {
            return true
        }
        return controller?.textView(textView, shouldReplaceContentsIn: range, with: string) ?? true
    }
}
