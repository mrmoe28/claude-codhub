//
//  AppState.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import SwiftData

@Observable
final class AppState {
    var selectedView: AppView = .errorFixer
    var isDarkMode: Bool = false
    var errorText: String = ""
    var generatedPrompt: String = ""
    var showingHistory: Bool = false
    var showingSettings: Bool = false
    
    enum AppView: String, CaseIterable {
        case errorFixer = "Error Fixer"
        case terminals = "Terminals"
        case history = "Knowledge Base"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .errorFixer: return "exclamationmark.triangle.fill"
            case .terminals: return "terminal"
            case .history: return "clock.fill"
            case .settings: return "gear"
            }
        }
    }
    
    func updateAppearance() {
        NSApp.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
    }
}