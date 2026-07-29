//
//  ShortcutOverlayView.swift
//  Boop
//
//  Hold ⌘ for a moment and every hotkey shows itself — iPad-style
//  discoverability for an app with no visible chrome.
//

import SwiftUI

struct ShortcutOverlayView: View {

    private struct Item {
        let keys: String
        let label: String
    }

    private struct Section {
        let title: String
        let items: [Item]
    }

    private let sections: [Section] = [
        Section(title: "Scripts", items: [
            Item(keys: "⌘B", label: "Script picker"),
            Item(keys: "⇧⌘B", label: "Run last script again"),
            Item(keys: "⌘↩", label: "Run buffer (JS / PHP)"),
            Item(keys: "⇧⌘R", label: "Reload scripts"),
            Item(keys: "⇧⌘K", label: "Clear editor"),
        ]),
        Section(title: "Pages", items: [
            Item(keys: "⌘N", label: "New page"),
            Item(keys: "⇧⌘W", label: "Close page"),
            Item(keys: "⇧⌘]", label: "Next page"),
            Item(keys: "⇧⌘[", label: "Previous page"),
        ]),
        Section(title: "Files", items: [
            Item(keys: "⌘O", label: "Open file"),
            Item(keys: "⌘S", label: "Save"),
            Item(keys: "⇧⌘P", label: "Markdown preview"),
            Item(keys: "⌘,", label: "Settings"),
        ]),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 2)
                    ForEach(section.items, id: \.keys) { item in
                        HStack(spacing: 10) {
                            Text(item.keys)
                                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .frame(minWidth: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.primary.opacity(0.08))
                                )
                            Text(item.label)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
