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
    // Deliberately NOT persisted: the buffer is disposable and starts empty,
    // so the language must too. Persisting it once left an auto-detected
    // "json" stuck across relaunches, blocking detection on new content.
    @Published var languageID: String = CodeLanguage.default.id.rawValue

    var language: CodeLanguage {
        get { CodeLanguage.allLanguages.first { $0.id.rawValue == languageID } ?? .default }
        set { languageID = newValue.id.rawValue; objectWillChange.send() }
    }

    /// Explicit menu picks stick; auto-detection only ever flips languages
    /// it set itself.
    func userPickedLanguage(_ id: String) {
        languageID = id
        languageWasAutoDetected = false
        objectWillChange.send()
    }

    // MARK: - Pages (in-memory only, by design — Boop stays disposable)

    struct Page {
        var text = ""
        var languageID: String = CodeLanguage.default.id.rawValue
        var autoDetected = false
        var fileURL: URL?
        var lastLoadedText = ""
    }

    @Published private(set) var pages: [Page] = [Page()]
    @Published private(set) var currentPageIndex = 0

    func newPage() {
        snapshotCurrentPage()
        pages.append(Page())
        loadPage(at: pages.count - 1)
    }

    func closeCurrentPage() {
        pages.remove(at: currentPageIndex)
        if pages.isEmpty {
            pages = [Page()]
        }
        loadPage(at: min(currentPageIndex, pages.count - 1))
    }

    func goToPage(_ index: Int) {
        guard pages.indices.contains(index), index != currentPageIndex else { return }
        snapshotCurrentPage()
        loadPage(at: index)
    }

    func nextPage() {
        guard pages.count > 1 else { return }
        snapshotCurrentPage()
        loadPage(at: (currentPageIndex + 1) % pages.count)
    }

    func previousPage() {
        guard pages.count > 1 else { return }
        snapshotCurrentPage()
        loadPage(at: (currentPageIndex - 1 + pages.count) % pages.count)
    }

    private func snapshotCurrentPage() {
        guard pages.indices.contains(currentPageIndex) else { return }
        pages[currentPageIndex] = Page(
            text: editor.textStorage.string,
            languageID: languageID,
            autoDetected: languageWasAutoDetected,
            fileURL: openedFileURL,
            lastLoadedText: lastLoadedText
        )
    }

    private func loadPage(at index: Int) {
        hidePreview()
        currentPageIndex = index
        let page = pages[index]
        setEditorText(page.text)
        languageID = page.languageID
        languageWasAutoDetected = page.autoDetected
        openedFileURL = page.fileURL
        lastLoadedText = page.lastLoadedText
        watchOpenedFile()
        objectWillChange.send()
    }

    // MARK: - Opened file

    @Published private(set) var openedFileURL: URL?
    /// Contents at last load/save, for dirty-buffer checks on reload.
    private var lastLoadedText = ""
    private var fileWatcher: DispatchSourceFileSystemObject?

    // MARK: - Markdown content detection

    private var detectionTask: Task<Void, Never>?
    private var languageWasAutoDetected = false

    private func scheduleContentDetection() {
        detectionTask?.cancel()
        detectionTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard let self, !Task.isCancelled else { return }
            self.detectContentLanguage()
        }
    }

    private func detectContentLanguage() {
        let sample = String(editor.textStorage.string.prefix(16_384))
        let detected = ContentDetector.detect(sample)

        if language.id == .plainText {
            if let detected {
                language = detected
                languageWasAutoDetected = true
            }
        } else if languageWasAutoDetected {
            // Follow the content: switch if it now reads as a different
            // language, fall back to plain text if the signals are gone.
            if let detected {
                if detected.id != language.id {
                    language = detected
                }
            } else {
                language = .default
                languageWasAutoDetected = false
            }
        }
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
        editor.onTextChange = { [weak self] in
            self?.scheduleContentDetection()
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

            // Don't clobber scratch content — files land on a fresh page.
            if !editor.textStorage.string.isEmpty {
                snapshotCurrentPage()
                pages.append(Page())
                loadPage(at: pages.count - 1)
            }

            setEditorText(text)
            lastLoadedText = text
            openedFileURL = url
            watchOpenedFile()

            let detected = CodeLanguage.detectLanguageFrom(url: url)
            language = detected
            languageWasAutoDetected = false

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

    func saveFile() {
        if let url = openedFileURL {
            write(to: url)
        } else {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = language.id == .markdown ? "Untitled.md" : "Untitled.txt"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            openedFileURL = url
            write(to: url)
            watchOpenedFile()
        }
    }

    private func write(to url: URL) {
        do {
            let text = editor.textStorage.string
            try text.write(to: url, atomically: true, encoding: .utf8)
            lastLoadedText = text
            setStatus(.success("Saved \(url.lastPathComponent)"))
        } catch {
            setStatus(.error("Could not save: \(error.localizedDescription)"))
        }
    }

    private func watchOpenedFile() {
        fileWatcher?.cancel()
        fileWatcher = nil
        guard let url = openedFileURL else { return }

        let fd = Darwin.open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let events = self.fileWatcher?.data ?? []
            if events.contains(.rename) || events.contains(.delete) {
                // Most editors save atomically (write + rename), so give the
                // new file a beat to land, then reload and re-arm the watch.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.reloadFromDisk()
                    self?.watchOpenedFile()
                }
            } else {
                self.reloadFromDisk()
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileWatcher = source
    }

    private func reloadFromDisk() {
        guard let url = openedFileURL,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }

        // Our own save also trips the watcher; nothing to do.
        guard text != editor.textStorage.string else {
            lastLoadedText = text
            return
        }
        // Never clobber edits that haven't been saved.
        guard editor.textStorage.string == lastLoadedText else {
            setStatus(.error("\(url.lastPathComponent) changed on disk — keeping your unsaved edits"))
            return
        }

        setEditorText(text)
        lastLoadedText = text
        if previewVisible {
            previewText = text
        }
        setStatus(.info("Reloaded \(url.lastPathComponent)"))
    }

    private func setEditorText(_ text: String) {
        // Must go through TextView so CodeEdit's undo manager sees the
        // mutation — editing the storage directly desyncs it and the next
        // keystroke hits an assertion in inverseMutation(for:).
        if let textView = editor.textView {
            textView.replaceCharacters(in: textView.documentRange, with: text)
            // A page/file swap is a new document; undoing across it would
            // resurrect the previous buffer's text into this one.
            textView._undoManager?.clearStack()
        } else {
            let storage = editor.textStorage
            storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
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
        // A cleared buffer is a fresh scratch buffer — back to plain text,
        // and detach the file so a reflexive ⌘S can't empty something on disk.
        languageID = CodeLanguage.default.id.rawValue
        languageWasAutoDetected = false
        openedFileURL = nil
        fileWatcher?.cancel()
        fileWatcher = nil
        lastLoadedText = ""
        hidePreview()
    }
}
