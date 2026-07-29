//
//  PlainTextCopyTests.swift
//  BoopTests
//
//  Copy must put plain text on the pasteboard — never the editor's
//  syntax-highlighted attributed string.
//

import XCTest
import AppKit
import CodeEditTextView

@MainActor
final class PlainTextCopyTests: XCTestCase {

    func testCopyWritesPlainStringOnly() {
        _ = PlainTextCopy.apply

        let textView = TextView(string: "SELECT * FROM users;")
        textView.selectionManager.setSelectedRange(NSRange(location: 0, length: 6))

        textView.copy(self)

        let pasteboard = NSPasteboard.general
        XCTAssertEqual(pasteboard.string(forType: .string), "SELECT")
        XCTAssertNil(pasteboard.data(forType: .rtf), "Pasteboard should carry no styled flavor")
    }

    func testCopyWithNoSelectionLeavesPasteboardAlone() {
        _ = PlainTextCopy.apply

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("previous contents", forType: .string)

        let textView = TextView(string: "hello")
        textView.selectionManager.setSelectedRange(NSRange(location: 2, length: 0))

        textView.copy(self)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "previous contents")
    }
}
