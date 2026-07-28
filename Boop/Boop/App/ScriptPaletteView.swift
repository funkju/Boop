//
//  ScriptPaletteView.swift
//  Boop
//
//  The ⌘B floating glass palette: search field + fuzzy results,
//  fully keyboard-driven.
//

import SwiftUI

struct ScriptPaletteView: View {
    @ObservedObject var model: AppModel

    @State private var query = ""
    @State private var results: [Script] = []
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.sparkles")
                    .foregroundStyle(.secondary)
                TextField("Search scripts…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($searchFocused)
                    .onSubmit(runSelected)
            }
            .padding(14)

            if !results.isEmpty {
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(results.enumerated()), id: \.element) { index, script in
                                ScriptRowView(script: script, isSelected: index == selectedIndex)
                                    .id(index)
                                    .onTapGesture { model.run(script) }
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 300)
                    .onChange(of: selectedIndex) {
                        proxy.scrollTo(selectedIndex)
                    }
                }
            }
        }
        .frame(width: 560)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .onAppear {
            query = ""
            results = []
            selectedIndex = 0
            // The editor's AppKit text view holds first responder until the
            // next runloop turn; focusing immediately gets silently dropped.
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
        .onChange(of: query) {
            results = model.scriptManager.search(query)
            selectedIndex = 0
        }
        .onKeyPress(.downArrow) {
            guard !results.isEmpty else { return .ignored }
            selectedIndex = min(selectedIndex + 1, results.count - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard !results.isEmpty else { return .ignored }
            selectedIndex = max(selectedIndex - 1, 0)
            return .handled
        }
        .onKeyPress(.tab) {
            guard !results.isEmpty else { return .ignored }
            selectedIndex = (selectedIndex + 1) % results.count
            return .handled
        }
        .onKeyPress(.escape) {
            model.hidePalette()
            return .handled
        }
    }

    private func runSelected() {
        guard results.indices.contains(selectedIndex) else { return }
        model.run(results[selectedIndex])
    }
}

struct ScriptRowView: View {
    let script: Script
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            iconImage
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(script.name ?? "Untitled")
                    .font(.system(size: 13, weight: .medium))
                Text(script.desc ?? "")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear),
            in: .rect(cornerRadius: 8)
        )
        .contentShape(.rect)
    }

    @ViewBuilder
    private var iconImage: some View {
        if let nsImage = Self.icon(for: script.icon) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
        }
    }

    /// Script icons ship in the asset catalog as "icons8-<name>"; scripts may
    /// also name an SF Symbol directly.
    private static func icon(for identifier: String?) -> NSImage? {
        guard let identifier else {
            return NSImage(named: "icons8-unknown")
        }
        if let named = NSImage(named: "icons8-\(identifier)") {
            return named
        }
        if let symbol = NSImage(systemSymbolName: identifier, accessibilityDescription: nil) {
            return symbol
        }
        return NSImage(named: "icons8-unknown")
    }
}
