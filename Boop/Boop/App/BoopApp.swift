//
//  BoopApp.swift
//  Boop
//
//  SwiftUI shell for the vibe fork.
//

import SwiftUI

/// Receives file-open events from Finder ("Open With Boop") and dock drops.
final class BoopAppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Task { @MainActor in
            AppModel.shared.open(url: url)
        }
    }
}

@main
struct BoopApp: App {
    @StateObject private var model = AppModel.shared
    @NSApplicationDelegateAdaptor(BoopAppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Boop", id: "main") {
            ContentView(model: model)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 620)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open…") {
                    model.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button(model.previewVisible ? "Hide Markdown Preview" : "Show Markdown Preview") {
                    model.togglePreview()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
            CommandMenu("Scripts") {
                Button(model.paletteVisible ? "Close Script Picker" : "Open Script Picker") {
                    model.togglePalette()
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Run Last Script Again") {
                    model.runLastScriptAgain()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])

                Divider()

                Button("Reload Scripts") {
                    model.reloadScripts()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Clear Editor") {
                    model.clearText()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Link("Boop Documentation", destination: URL(string: "https://boop.okat.best/docs/")!)
                Link("More Scripts", destination: URL(string: "https://boop.okat.best/scripts/")!)
            }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
