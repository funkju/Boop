//
//  BoopApp.swift
//  Boop
//
//  SwiftUI shell for the vibe fork.
//

import SwiftUI

@main
struct BoopApp: App {
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        Window("Boop", id: "main") {
            ContentView(model: model)
        }
        .defaultSize(width: 900, height: 620)
        .commands {
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
