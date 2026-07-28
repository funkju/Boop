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
                // Keep the first lines clear of the title-bar strip (traffic
                // lights, status text, language menu).
                contentInsets: NSEdgeInsets(top: 48, left: 0, bottom: 0, right: 0)
            ),
            peripherals: .init(
                showMinimap: model.showMinimap,
                showFoldingRibbon: model.showFoldingRibbon
            )
        )
    }

    var body: some View {
        ZStack {
            // The editor's scroll view no longer draws its own background
            // (see EditorCoordinator), so this tint sits between the window's
            // glass material and the text.
            Color(nsColor: (colorScheme == .dark ? BoopTheme.dark : BoopTheme.light).background)
                .ignoresSafeArea()

            SourceEditor(
                model.editor.textStorage,
                language: model.language,
                configuration: configuration,
                state: $editorState,
                coordinators: [model.editor]
            )
            .ignoresSafeArea()

            if model.previewVisible {
                MarkdownPreviewView(text: model.previewText)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

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
        .animation(.easeOut(duration: 0.15), value: model.previewVisible)
        // Real toolbar items so macOS itself lines them up with the
        // traffic lights; the toolbar chrome stays hidden.
        .toolbar {
            // sharedBackgroundVisibility(.hidden) opts out of the automatic
            // Liquid Glass capsules around toolbar items — bare text only.
            ToolbarItem(placement: .principal) {
                StatusPill(model: model)
            }
            .sharedBackgroundVisibility(.hidden)
            // Only offer the preview when the document is markdown (keep it
            // reachable while previewing so you can always flip back).
            if model.language.id == .markdown || model.previewVisible {
                ToolbarItem(placement: .primaryAction) {
                    PreviewToggle(model: model)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            ToolbarItem(placement: .primaryAction) {
                LanguageMenu(model: model)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .containerBackground(.ultraThinMaterial, for: .window)
    }
}
