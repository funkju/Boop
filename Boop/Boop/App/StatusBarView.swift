//
//  StatusBarView.swift
//  Boop
//
//  Bottom status strip: script messages on the left, language picker on
//  the right.
//

import SwiftUI
import CodeEditLanguages

struct StatusBarView: View {
    @ObservedObject var model: AppModel

    private var statusColor: Color {
        switch model.status {
        case .normal, .help: return .secondary
        case .info: return .blue
        case .error: return .red
        case .success: return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            Text(model.status.message)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Picker("", selection: Binding(
                get: { model.languageID },
                set: { model.languageID = $0; model.objectWillChange.send() }
            )) {
                ForEach(CodeLanguage.allLanguages, id: \.id.rawValue) { lang in
                    Text(lang.id.rawValue.capitalized).tag(lang.id.rawValue)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
