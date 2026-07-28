//
//  TopBarView.swift
//  Boop
//
//  Title-bar controls: script status/results centered (toolbar principal
//  item), and a nearly invisible language selector on the trailing edge.
//

import SwiftUI
import CodeEditLanguages

/// Centered status message, shown in the title bar.
struct StatusPill: View {
    @ObservedObject var model: AppModel

    private var statusColor: Color {
        switch model.status {
        case .normal, .help: return .secondary
        case .info: return .blue
        case .error: return .red
        case .success: return .green
        }
    }

    private var isTransientStatus: Bool {
        switch model.status {
        case .normal: return false
        default: return true
        }
    }

    var body: some View {
        Group {
            if isTransientStatus {
                Text(model.status.message)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text(model.status.message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .opacity(0.55)
                    .lineLimit(1)
            }
        }
        .animation(.spring(duration: 0.25), value: model.status)
    }
}

/// Almost invisible language selector for the title bar's trailing edge.
struct LanguageMenu: View {
    @ObservedObject var model: AppModel

    @State private var hovering = false

    private var isPlainText: Bool {
        model.language.id == .plainText
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { model.languageID },
            set: { model.languageID = $0; model.objectWillChange.send() }
        )
    }

    var body: some View {
        Menu {
            Picker("Language", selection: languageBinding) {
                Text("Plain Text").tag(CodeLanguage.default.id.rawValue)
                Divider()
                ForEach(CodeLanguage.allLanguages.filter { $0.id != .plainText }, id: \.id.rawValue) { lang in
                    Text(lang.tsName).tag(lang.id.rawValue)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Group {
                if isPlainText {
                    Image(systemName: "textformat")
                        .font(.system(size: 10))
                } else {
                    Text(model.language.tsName.lowercased())
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .opacity(hovering ? 1 : (isPlainText ? 0.25 : 0.5))
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}
