//
//  ContentView.swift
//  Boop
//
//  Editor + status bar, with the script palette floating above as glass.
//

import SwiftUI
import CodeEditSourceEditor
import CodeEditLanguages

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var editorState = SourceEditorState()

    private var configuration: SourceEditorConfiguration {
        SourceEditorConfiguration(
            appearance: .init(
                theme: colorScheme == .dark ? BoopTheme.dark : BoopTheme.light,
                font: .monospacedSystemFont(ofSize: model.fontSize, weight: .regular),
                wrapLines: model.wrapLines
            ),
            layout: .init(
                // Keep the first lines clear of the traffic lights now that
                // the title bar is hidden.
                contentInsets: NSEdgeInsets(top: 34, left: 0, bottom: 0, right: 0)
            ),
            peripherals: .init(
                showMinimap: model.showMinimap,
                showFoldingRibbon: model.showFoldingRibbon
            )
        )
    }

    var body: some View {
        ZStack {
            SourceEditor(
                model.editor.textStorage,
                language: model.language,
                configuration: configuration,
                state: $editorState,
                coordinators: [model.editor]
            )
            .ignoresSafeArea()

            if model.paletteVisible {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { model.hidePalette() }
                    .transition(.opacity)

                ScriptPaletteView(model: model)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(duration: 0.2), value: model.paletteVisible)
        .overlay(alignment: .top) {
            TopBarView(model: model)
                .animation(.spring(duration: 0.25), value: model.status)
        }
        .containerBackground(.ultraThinMaterial, for: .window)
    }
}
