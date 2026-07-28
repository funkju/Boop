//
//  ScriptManager.swift
//  Yup
//
//  Created by Ivan on 1/15/17.
//  Copyright © 2017 OKatBest. All rights reserved.
//

import AppKit
import Fuse
import CodeEditTextView

class ScriptManager: ObservableObject {

    static let userPreferencesPathKey = "scriptsFolderPath"
    static let userPreferencesDataKey = "scriptsFolderData"

    /// Reports script status (errors, info, reload confirmations) to the UI.
    var onStatus: ((Status) -> Void)?

    let fuse = Fuse(threshold: 0.2)
    @Published private(set) var scripts = [Script]()

    let currentAPIVersion = 1.0

    var lastScript: Script?

    init() {
        loadDefaultScripts()
        loadUserScripts()
    }

    static func setBookmarkData(url: URL) throws {

        let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)

        UserDefaults.standard.set(data, forKey: ScriptManager.userPreferencesDataKey)
    }

    /// Load built in scripts
    func loadDefaultScripts(){
        let urls = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: "scripts")

        urls?.forEach { script in
            loadScript(url: script, builtIn: true)
        }
    }

    /// Load user scripts
    func loadUserScripts(){

        do {

            guard let url = try ScriptManager.getBookmarkURL() else {
                return
            }

            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            urls.forEach { url in
                guard url.path.hasSuffix(".js") else {
                    return
                }
                loadScript(url: url, builtIn: false)
            }

        }
        catch let error {
            print(error)
            return
        }
    }

    /// Parses a script file
    private func loadScript(url: URL, builtIn: Bool){
        do{
            let script = try String(contentsOf: url)

            // This is inspired by the ISF file format by Vidvox
            // Thanks to them for the idea and their awesome work

            guard
                let openComment = script.range(of: "/**"),
                let closeComment = script.range(of: "**/")
                else {
                    throw NSError()
            }

            let meta = script[openComment.upperBound..<closeComment.lowerBound]

            let json = try JSONSerialization.jsonObject(with: meta.data(using: .utf8)!, options: .allowFragments) as! [String: Any]

            let scriptObject = Script(url: url, script: script, parameters: json, builtIn: builtIn, delegate: self)

            scripts.append(scriptObject)


        } catch {
            print("Unable to load ", url)
        }
    }

    func search(_ query: String) -> [Script] {


        guard query.count < 20 else {
            // If the query is too long let's just ignore it.
            // It's probably the user pasting the wrong thing
            // in the search box by accident which overwhelms
            // fuse and crashes the app. Whoops!

            return []
        }

        guard query != "*" else {

            return scripts.sorted { left, right in
                left.name ?? "" < right.name ?? ""
            }
        }

        let results = fuse.search(query, in: scripts)

        return results.filter { result in
            result.score < 0.4 // Filter low quality results
        }.sorted { left, right in
            let leftScore = left.score - (scripts[left.index].bias ?? 0)
            let rightScore = right.score - (scripts[right.index].bias ?? 0)
            return leftScore < rightScore
        }.map { result in
            scripts[result.index]
        }
    }

    func runScript(_ script: Script, in textView: TextView) {

        let fullText = textView.string

        lastScript = script

        let selectedRanges = textView.selectionManager.textSelections
            .map(\.range)
            .filter { $0.length > 0 }

        guard !selectedRanges.isEmpty else {

            // No selection, run on full text

            let insertPosition = textView.selectionManager.textSelections.first?.range.location
            let result = runScript(script, fullText: fullText, insertIndex: insertPosition)

            textView.undoManager?.beginUndoGrouping()
            textView.replaceCharacters(in: textView.documentRange, with: result)
            textView.undoManager?.endUndoGrouping()

            return
        }

        // Fun fact: You can have multi selections! Which means we need to disable
        // the ability to edit `fullText` while in selection mode, otherwise the
        // some scripts may accidentally run multiple time over the full text.
        //
        // Replacements are applied back-to-front so earlier ranges keep their
        // positions as the text shifts.

        let pairs = selectedRanges
            .map { range -> (NSRange, String) in
                let value = (fullText as NSString).substring(with: range)
                return (range, runScript(script, selection: value, fullText: fullText))
            }
            .sorted { $0.0.location > $1.0.location }

        textView.undoManager?.beginUndoGrouping()
        pairs.forEach { (range, value) in
            textView.replaceCharacters(in: range, with: value)
        }
        textView.undoManager?.endUndoGrouping()
    }

    func runScript(_ script: Script, selection: String? = nil, fullText: String, insertIndex: Int? = nil) -> String {
        let scriptExecution = ScriptExecution(selection: selection, fullText: fullText, script: script, insertIndex: insertIndex)

        onStatus?(.normal)
        script.run(with: scriptExecution)

        return scriptExecution.text ?? ""
    }

    func runScriptAgain(in textView: TextView) {
        guard let script = lastScript else {
            NSSound.beep()
            return
        }

        runScript(script, in: textView)
    }

    func reloadScripts() {
        lastScript = nil
        scripts.removeAll()
        loadDefaultScripts()
        loadUserScripts()

        onStatus?(.success("Reloaded Scripts"))
    }

    static func getBookmarkURL() throws -> URL? {

        guard let data = UserDefaults.standard.data(forKey: ScriptManager.userPreferencesDataKey) else {
            // No user path specified, abbandon ship!
            return nil
        }

        var isBookmarkStale = false

        let url = try URL.init(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isBookmarkStale)

        if(isBookmarkStale) {
            try ScriptManager.setBookmarkData(url: url)
        }

        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }

        return url
    }

}

extension ScriptManager: ScriptDelegate {
    func onScriptError(message: String) {
        onStatus?(.error(message))
    }

    func onScriptInfo(message: String) {
        onStatus?(.info(message))
    }

}
