//
//  BufferRunnerTests.swift
//  BoopTests
//
//  Pins the in-buffer REPL: result-block splicing is stable across re-runs,
//  JavaScript evaluates in-process, PHP shells out to the local binary.
//

import XCTest

final class BufferRunnerTests: XCTestCase {

    // MARK: - Result block splicing

    func testFormatsSingleLineResult() {
        XCTAssertEqual(BufferRunner.formatResultBlock("42"), "// => 42")
    }

    func testFormatsMultiLineResult() {
        XCTAssertEqual(
            BufferRunner.formatResultBlock("first\nsecond"),
            "// => first\n//    second"
        )
    }

    func testStripsTrailingResultBlock() {
        let text = "1 + 2\n// => 3"
        XCTAssertEqual(BufferRunner.stripTrailingResultBlock(text), "1 + 2")
    }

    func testStripsMultiLineBlockAndBlankLines() {
        let text = "let x = [1, 2]\nx\n\n// => [\n//      1,\n//      2\n//    ]\n"
        XCTAssertEqual(BufferRunner.stripTrailingResultBlock(text), "let x = [1, 2]\nx")
    }

    func testStripIsStableAcrossReruns() {
        let code = "const a = 2\na * 21"
        let once = code + "\n" + BufferRunner.formatResultBlock("42")
        XCTAssertEqual(BufferRunner.stripTrailingResultBlock(once), code)
        let twice = BufferRunner.stripTrailingResultBlock(once) + "\n" + BufferRunner.formatResultBlock("42")
        XCTAssertEqual(twice, once)
    }

    func testFormatsErrorBlock() {
        XCTAssertEqual(
            BufferRunner.formatErrorBlock("ReferenceError: nope is not defined"),
            "// !! ReferenceError: nope is not defined"
        )
    }

    func testStripsTrailingErrorBlock() {
        let text = "nope()\n// !! ReferenceError: nope is not defined"
        XCTAssertEqual(BufferRunner.stripTrailingResultBlock(text), "nope()")
    }

    func testErrorBlockReplacedByResultOnRerun() {
        let failed = "1 + 2\n" + BufferRunner.formatErrorBlock("oops")
        let code = BufferRunner.stripTrailingResultBlock(failed)
        XCTAssertEqual(code + "\n" + BufferRunner.formatResultBlock("3"), "1 + 2\n// => 3")
    }

    func testLeavesOrdinaryTrailingCommentsAlone() {
        let text = "doThing()\n// regular comment at the end"
        XCTAssertEqual(BufferRunner.stripTrailingResultBlock(text), text)
    }

    // MARK: - JavaScript

    func testRunsJavaScriptExpression() {
        XCTAssertEqual(try BufferRunner.runJavaScript("1 + 2").get(), "3")
    }

    func testJavaScriptObjectResultIsJSON() {
        let output = try? BufferRunner.runJavaScript("({ a: 1 })").get()
        XCTAssertEqual(output, "{\n  \"a\": 1\n}")
    }

    func testJavaScriptConsoleLogIsCaptured() {
        let output = try? BufferRunner.runJavaScript("console.log('hi', 2); 'done'").get()
        XCTAssertEqual(output, "hi 2\ndone")
    }

    func testJavaScriptErrorFails() {
        if case .success = BufferRunner.runJavaScript("nope(") {
            XCTFail("Syntax error should not succeed")
        }
    }

    // MARK: - PHP

    func testRunsBarePHPStatements() throws {
        try XCTSkipIf(BufferRunner.phpPath == nil, "No php binary on this machine")
        XCTAssertEqual(try BufferRunner.runPHP("$x = 21; echo $x * 2;").get(), "42")
    }

    func testPHPWithOpenTagStillRuns() throws {
        try XCTSkipIf(BufferRunner.phpPath == nil, "No php binary on this machine")
        XCTAssertEqual(try BufferRunner.runPHP("<?php echo strtoupper(\"ok\");").get(), "OK")
    }

    func testPHPParseErrorFails() throws {
        try XCTSkipIf(BufferRunner.phpPath == nil, "No php binary on this machine")
        if case .success = BufferRunner.runPHP("echo (;") {
            XCTFail("Parse error should not succeed")
        }
    }
}
