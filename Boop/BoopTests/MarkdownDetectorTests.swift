//
//  MarkdownDetectorTests.swift
//  BoopTests
//
//  Pins the content-based markdown sniffing: real markdown is detected,
//  look-alikes (shell comments, prose, JSON) are not.
//

import XCTest

final class MarkdownDetectorTests: XCTestCase {

    func testDetectsTypicalMarkdownDocument() {
        let text = """
        # Release Notes

        Some intro text with **bold** and a [link](https://example.com).

        ## Changes

        - Fixed the thing
        - Added the other thing
        - Removed `legacyFlag`

        > Note: restart required.
        """
        XCTAssertTrue(MarkdownDetector.looksLikeMarkdown(text))
    }

    func testDetectsReadmeWithFencedCode() {
        let text = """
        # Install

        Run this:

        ```sh
        brew install thing
        thing --setup
        ```

        Then edit `~/.thingrc` and set **enabled** to true.

        1. First step
        2. Second step
        """
        XCTAssertTrue(MarkdownDetector.looksLikeMarkdown(text))
    }

    func testRejectsShellScriptComments() {
        let text = """
        #!/bin/sh
        # This script cleans caches
        # Author: someone
        # Usage: clean.sh [target]
        set -e
        rm -r "$HOME/Library/Caches/thing"
        echo done
        """
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown(text))
    }

    func testRejectsPlainProse() {
        let text = """
        Hey, just wanted to follow up on the meeting from earlier today.
        I think we should move the launch to next week. Let me know if
        that works for you and I will update the calendar.

        Thanks!
        """
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown(text))
    }

    func testRejectsJSON() {
        let text = """
        {
          "name": "boop",
          "version": "1.0.0",
          "scripts": ["a", "b", "c"],
          "nested": { "key": "value" }
        }
        """
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown(text))
    }

    func testRejectsEmptyAndTrivialText() {
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown(""))
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown("hello world"))
    }

    func testCommentsInsideFencesDoNotCountAsHeadings() {
        let text = """
        ```sh
        # not a heading
        # also not a heading
        # still not a heading
        ```
        """
        XCTAssertFalse(MarkdownDetector.looksLikeMarkdown(text))
    }
}
