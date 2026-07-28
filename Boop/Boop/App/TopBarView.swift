//
//  TopBarView.swift
//  Boop
//
//  Floating top strip: script status/results centered, and a nearly
//  invisible language selector tucked in the top-right corner.
//

import SwiftUI
import CodeEditLanguages

struct TopBarView: View {
    @ObservedObject var model: AppModel

    @State private var hoveringLanguage = false

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
        ZStack(alignment: .top) {
            statusView
                .frame(maxWidth: .infinity, alignment: .center)
            languageMenu
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.top, 7)
    }

    // MARK: - Status (centered, like classic Boop's result messages)

    @ViewBuilder
    private var statusView: some View {
        if isTransientStatus {
            Text(model.status.message)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .glassEffect(.regular, in: .capsule)
                .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
            Text(model.status.message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .opacity(0.55)
                .lineLimit(1)
        }
    }

    // MARK: - Language selector (top right, almost invisible)

    private var isPlainText: Bool {
        model.language.id == .plainText
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { model.languageID },
            set: { model.languageID = $0; model.objectWillChange.send() }
        )
    }

    private var languageMenu: some View {
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
        .opacity(hoveringLanguage ? 1 : (isPlainText ? 0.25 : 0.5))
        .onHover { hoveringLanguage = $0 }
        .animation(.easeOut(duration: 0.15), value: hoveringLanguage)
    }
}
