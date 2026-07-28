//
//  MarkdownPreviewView.swift
//  Boop
//
//  Rendered markdown, shown as a full-window overlay above the editor.
//

import SwiftUI
import MarkdownUI

struct MarkdownPreviewView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    /// Opaque version of the editor tint so the text underneath can't
    /// bleed through the preview.
    private var backdrop: Color {
        let theme = colorScheme == .dark ? BoopTheme.dark : BoopTheme.light
        return Color(nsColor: theme.background.withAlphaComponent(1))
    }

    var body: some View {
        ScrollView {
            Markdown(text)
                .markdownTheme(.docC)
                .textSelection(.enabled)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 56)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity)
        }
        .background(backdrop.ignoresSafeArea())
    }
}
