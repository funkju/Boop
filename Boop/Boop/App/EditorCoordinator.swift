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
    }

    func focus() {
        guard let textView = controller?.textView else { return }
        textView.window?.makeFirstResponder(textView)
    }

    func destroy() {
        controller = nil
    }
}
