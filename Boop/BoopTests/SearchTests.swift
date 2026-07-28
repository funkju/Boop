//
//  SearchTests.swift
//  BoopTests
//
//  Fuzzy search should surface scripts whose name/tags actually relate to
//  the query, in a sensible order.
//

import XCTest

class SearchTests: XCTestCase {

    let manager = ScriptManager()

    private func names(for query: String) -> [String] {
        manager.search(query).compactMap(\.name)
    }

    func testFormatQueryReturnsFormatters() {
        let results = names(for: "format")

        XCTAssertFalse(results.isEmpty, "\"format\" should match the formatter scripts")

        // Every formatter in the bundle should be found…
        XCTAssertTrue(results.contains("Format JSON"), "got: \(results)")

        // …and the top results should all be format-related.
        let top = results.prefix(5)
        for name in top {
            let script = manager.scripts.first { $0.name == name }
            let haystack = "\(name) \(script?.tags ?? "")".lowercased()
            XCTAssertTrue(
                haystack.contains("format") || haystack.contains("prett") || haystack.contains("beaut") || haystack.contains("clean") || haystack.contains("indent"),
                "\"\(name)\" is not format-related; top results were: \(Array(top))"
            )
        }

        // Known-bad results from the bug report must not outrank real matches.
        for bogus in ["Reverse Lines", "Reverse String", "Shuffle Lines"] {
            if let bogusIndex = results.firstIndex(of: bogus),
               let realIndex = results.firstIndex(of: "Format JSON") {
                XCTAssertGreaterThan(bogusIndex, realIndex, "\"\(bogus)\" outranked \"Format JSON\": \(results)")
            }
        }
    }

    func testExactNameQueryIsTopResult() {
        let results = names(for: "base64")
        XCTAssertEqual(results.first?.lowercased().contains("base64"), true, "got: \(results)")
    }

    func testNatoQueryFindsNatoScript() {
        let results = names(for: "nato")
        XCTAssertTrue(
            results.prefix(3).contains { $0.lowercased().contains("nato") },
            "got: \(results)"
        )
    }

    func testStarReturnsEverythingSortedByName() {
        let results = names(for: "*")
        XCTAssertEqual(results.count, manager.scripts.count)
        XCTAssertEqual(results, results.sorted())
    }

    func testSearchIsCaseInsensitive() {
        XCTAssertEqual(names(for: "Format"), names(for: "format"), "capitalized query must match lowercase")
    }

    func testProgressiveTypingConvergesToFormatters() {
        // Simulates typing F-o-r-m-a-t one keystroke at a time; whatever the
        // intermediate results, the final query must surface the formatters.
        var final: [String] = []
        for end in 1...6 {
            final = names(for: String("Format".prefix(end)))
        }
        XCTAssertTrue(final.contains("Format JSON"), "got: \(final)")
        XCTAssertFalse(final.prefix(4).contains("Reverse Lines"), "got: \(final)")
        XCTAssertFalse(final.prefix(4).contains("Shuffle Lines"), "got: \(final)")
    }

    func testUnrelatedQueryReturnsNothingOrFewResults() {
        // A nonsense query should not fuzzily match half the catalog.
        let results = names(for: "zzqxv")
        XCTAssertTrue(results.isEmpty, "nonsense query matched: \(results)")
    }
}
