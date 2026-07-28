//
//  SettingsView.swift
//  Boop
//
//  Replaces the old Preferences storyboard.
//

import SwiftUI
import CodeEditLanguages

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            editorTab
                .tabItem { Label("Editor", systemImage: "text.and.command.interface.window") }
            scriptsTab
                .tabItem { Label("Scripts", systemImage: "curlybraces") }
        }
        .frame(width: 440)
    }

    private var editorTab: some View {
        Form {
            Slider(value: model.$fontSize, in: 10...24, step: 1) {
                Text("Font size: \(Int(model.fontSize))")
            }
            Toggle("Wrap lines", isOn: model.$wrapLines)
            Toggle("Show minimap", isOn: model.$showMinimap)
            Toggle("Show code folding ribbon", isOn: model.$showFoldingRibbon)

            Picker("Default language", selection: model.$languageID) {
                ForEach(CodeLanguage.allLanguages, id: \.id.rawValue) { lang in
                    Text(lang.tsName).tag(lang.id.rawValue)
                }
            }
        }
        .padding(20)
    }

    private var scriptsTab: some View {
        Form {
            LabeledContent("Custom scripts folder") {
                Text(currentScriptsFolder)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Button("Choose Folder…") { chooseFolder() }
                Button("Reload Scripts") { model.reloadScripts() }
            }

            Text("Scripts in this folder are loaded alongside the built-in ones. ⇧⌘R reloads them without relaunching.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var currentScriptsFolder: String {
        guard let url = try? ScriptManager.getBookmarkURL() else {
            return "None"
        }
        return url.path
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try ScriptManager.setBookmarkData(url: url)
            model.reloadScripts()
        } catch {
            model.setStatus(.error("Could not save scripts folder: \(error.localizedDescription)"))
        }
    }
}
