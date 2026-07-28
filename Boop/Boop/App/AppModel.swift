//
//  AppModel.swift
//  Boop
//
//  Central observable state: editor access, status line, palette, settings.
//

import AppKit
import SwiftUI
import CodeEditLanguages

@MainActor
final class AppModel: ObservableObject {

    static let shared = AppModel()

    let scriptManager = ScriptManager()
    let editor = EditorCoordinator()

    @Published var paletteVisible = false
    @Published private(set) var status: Status = .normal

    // MARK: - Settings

    @AppStorage("editorFontSize") var fontSize: Double = 14
    @AppStorage("editorWrapLines") var wrapLines: Bool = true
    @AppStorage("editorShowMinimap") var showMinimap: Bool = false
    @AppStorage("editorShowFoldingRibbon") var showFoldingRibbon: Bool = true
    @AppStorage("editorLanguage") var languageID: String = CodeLanguage.json.id.rawValue

    var language: CodeLanguage {
        get { CodeLanguage.allLanguages.first { $0.id.rawValue == languageID } ?? .default }
        set { languageID = newValue.id.rawValue; objectWillChange.send() }
    }

    // MARK: - Status queue
    //
    // Transient statuses (info/error/success) queue up and each display for a
    // few seconds; normal/help apply immediately and flush the queue.

    private var statusQueue: [Status] = []
    private var statusTask: Task<Void, Never>?

    func setStatus(_ newStatus: Status) {
        switch newStatus {
        case .normal, .help:
            statusTask?.cancel()
            statusTask = nil
            statusQueue.removeAll()
            status = newStatus
        default:
            statusQueue.append(newStatus)
            pumpStatusQueue()
        }
    }

    private func pumpStatusQueue() {
        guard statusTask == nil else { return }
        guard !statusQueue.isEmpty else { return }

        let next = statusQueue.removeFirst()
        status = next

        statusTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self, !Task.isCancelled else { return }
            self.statusTask = nil
            if self.statusQueue.isEmpty {
                self.status = .normal
            } else {
                self.pumpStatusQueue()
            }
        }
    }

    // MARK: - Actions

    private init() {
        scriptManager.onStatus = { [weak self] status in
            self?.setStatus(status)
        }
    }

    func togglePalette() {
        paletteVisible.toggle()
        setStatus(paletteVisible ? .help("Select your action") : .normal)
        if paletteVisible {
            editor.blur()
        } else {
            editor.focus()
        }
    }

    func hidePalette() {
        guard paletteVisible else { return }
        paletteVisible = false
        setStatus(.normal)
        editor.focus()
    }

    func run(_ script: Script) {
        hidePalette()
        guard let textView = editor.textView else { return }
        scriptManager.runScript(script, in: textView)
    }

    func runLastScriptAgain() {
        guard let textView = editor.textView else { return }
        scriptManager.runScriptAgain(in: textView)
    }

    func reloadScripts() {
        scriptManager.reloadScripts()
    }

    func clearText() {
        guard let textView = editor.textView else { return }
        textView.replaceCharacters(in: textView.documentRange, with: "")
    }
}
