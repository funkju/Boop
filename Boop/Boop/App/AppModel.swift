//
//  AppModel.swift
//  Boop
//
//  Central observable state: editor access, status line, palette, settings.
//

import AppKit
import SwiftUI
import CodeEditLanguages
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {

    static let shared = AppModel()

    let scriptManager = ScriptManager()
    let editor = EditorCoordinator()

    @Published var paletteVisible = false
    @Published private(set) var status: Status = .normal

    // MARK: - Markdown preview

    @Published private(set) var previewVisible = false
    /// Snapshot of the document taken when the preview opens; the editor
    /// stays alive underneath, hidden by the preview's solid background.
    @Published private(set) var previewText = ""

    // MARK: - Settings

    @AppStorage("editorFontSize") var fontSize: Double = 14
    @AppStorage("editorWrapLines") var wrapLines: Bool = true
    @AppStorage("editorShowMinimap") var showMinimap: Bool = false
    @AppStorage("editorShowFoldingRibbon") var showFoldingRibbon: Bool = true
    // Fresh key on purpose: earlier builds stored "json" under
    // "editorLanguage"; documents should start as unobtrusive plain text.
    @AppStorage("editorLanguageID") var languageID: String = CodeLanguage.default.id.rawValue

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

    func togglePreview() {
        if previewVisible {
            hidePreview()
        } else {
            showPreview()
        }
    }

    func showPreview() {
        previewText = editor.textStorage.string
        previewVisible = true
        setStatus(.help("Markdown preview — ⇧⌘P to edit"))
        editor.blur()
    }

    func hidePreview() {
        guard previewVisible else { return }
        previewVisible = false
        setStatus(.normal)
        editor.focus()
    }

    // MARK: - File opening

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let storage = editor.textStorage
            storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)

            let detected = CodeLanguage.detectLanguageFrom(url: url)
            language = detected

            if detected.id == .markdown {
                showPreview()
            } else {
                hidePreview()
                setStatus(.info("Opened \(url.lastPathComponent)"))
            }
        } catch {
            setStatus(.error("Could not open \(url.lastPathComponent)"))
        }
    }

    func run(_ script: Script) {
        hidePalette()
        guard let textView = editor.textView else { return }
        scriptManager.runScript(script, in: textView)
        if previewVisible {
            previewText = editor.textStorage.string
        }
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
