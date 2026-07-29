//
//  ShortcutOverlayView.swift
//  Boop
//
//  Hold ⌘ for a moment and every hotkey shows itself — iPad-style
//  discoverability for an app with no visible chrome. Rendered in its own
//  floating panel, centered on the screen rather than inside the window.
//

import SwiftUI
import AppKit

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
        HStack(alignment: .top, spacing: 44) {
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 13) {
                    Text(section.title.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 3)
                    ForEach(section.items, id: \.keys) { item in
                        HStack(spacing: 12) {
                            Text(item.keys)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(minWidth: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primary.opacity(0.08))
                                )
                            Text(item.label)
                                .font(.system(size: 14.5))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(40)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

/// Borderless floating panel that hosts the overlay, centered on whichever
/// screen holds the key window. Never takes focus, never takes clicks.
@MainActor
final class ShortcutOverlayPanel {

    private var panel: NSPanel?

    var isVisible: Bool { panel != nil }

    func show() {
        guard panel == nil else { return }

        let hosting = NSHostingView(rootView: ShortcutOverlayView())
        hosting.frame.size = hosting.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: hosting.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        // The app forces dark mode; a standalone panel would follow the
        // system appearance without this.
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.contentView = hosting

        if let screen = NSApp.keyWindow?.screen ?? NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.midX - hosting.frame.width / 2,
                y: frame.midY - hosting.frame.height / 2
            ))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        self.panel = panel
    }

    func hide() {
        guard let panel else { return }
        self.panel = nil
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
