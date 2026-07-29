//
//  ContentDetectorTests.swift
//  BoopTests
//
//  JSON and PHP sniffing, plus the ordering rules between the three
//  detected languages.
//

import XCTest
import CodeEditLanguages

final class ContentDetectorTests: XCTestCase {

    // MARK: - JSON

    func testDetectsStrictJSON() {
        let text = """
        {
          "name": "boop",
          "version": "1.0.0",
          "nested": { "key": [1, 2, 3] }
        }
        """
        XCTAssertTrue(ContentDetector.looksLikeJSON(text))
        XCTAssertEqual(ContentDetector.detect(text)?.id, .json)
    }

    func testDetectsSloppyJSONWithUnquotedKeys() {
        let text = """
        {
          name: "boop",
          count: 3,
          tags: ["a", "b",],
        }
        """
        XCTAssertTrue(ContentDetector.looksLikeJSON(text))
    }

    func testDetectsJSONArray() {
        let text = #"[{"id": 1}, {"id": 2}, {"id": 3}]"#
        XCTAssertTrue(ContentDetector.looksLikeJSON(text))
    }

    func testRejectsBracketedProse() {
        XCTAssertFalse(ContentDetector.looksLikeJSON("[TODO: fix the thing]"))
        XCTAssertFalse(ContentDetector.looksLikeJSON("plain text, no structure"))
    }

    // MARK: - PHP

    func testDetectsPHPByOpenTag() {
        let text = """
        <?php
        echo "hello";
        """
        XCTAssertTrue(ContentDetector.looksLikePHP(text))
        XCTAssertEqual(ContentDetector.detect(text)?.id, .php)
    }

    func testDetectsPHPSnippetWithoutTag() {
        let text = """
        $user = User::find($id);
        $name = $user->profile->displayName;
        foreach ($user->orders as $order) {
            $total = $total + $order->amount;
        }
        """
        XCTAssertTrue(ContentDetector.looksLikePHP(text))
        XCTAssertEqual(ContentDetector.detect(text)?.id, .php)
    }

    func testDetectsShortPHPWithBuiltinCall() {
        // The buffer that ran as JavaScript by mistake: one assignment plus
        // a builtin call on a $var is enough to read as PHP.
        let text = """
        $test = 14;
        ucwords($test);
        """
        XCTAssertTrue(ContentDetector.looksLikePHP(text))
        XCTAssertEqual(ContentDetector.detect(text)?.id, .php)
    }

    func testRejectsShellScriptDollarVariables() {
        let text = """
        #!/bin/sh
        NAME="world"
        echo "hello $NAME"
        cp "$SRC" "$DST"
        """
        XCTAssertFalse(ContentDetector.looksLikePHP(text))
    }

    // MARK: - Ordering

    func testMarkdownWithPHPFenceStaysMarkdown() {
        let text = """
        # Usage

        Install it, then add **this** to your controller:

        ```php
        <?php
        $client = new Client();
        $client->send($payload);
        ```

        - Works on PHP 8
        - See the [docs](https://example.com)
        """
        XCTAssertEqual(ContentDetector.detect(text)?.id, .markdown)
    }

    func testProseDetectsNothing() {
        let text = """
        Hey, just wanted to follow up on the meeting from earlier today.
        I think we should move the launch to next week.
        """
        XCTAssertNil(ContentDetector.detect(text))
    }
}
