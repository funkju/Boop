//
//  Status.swift
//  Boop
//
//  Status line messages reported by the script engine and UI.
//

import Foundation

enum Status: Equatable {
    case normal
    case help(String)
    case info(String)
    case error(String)
    case success(String)

    var message: String {
        switch self {
        case .normal: return "Press ⌘B to get started"
        case .help(let value), .info(let value), .error(let value), .success(let value):
            return value
        }
    }
}
