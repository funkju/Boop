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

    var textView: TextView? {
        controller?.textView
    }

    func prepareCoordinator(controller: TextViewController) {
        self.controller = controller
        // NSClipView reports itself opaque whenever it draws a background —
        // even a transparent color — which blocks the window's glass
        // material. Stop drawing; the tint lives in ContentView instead.
        controller.scrollView?.drawsBackground = false
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
    }
}
