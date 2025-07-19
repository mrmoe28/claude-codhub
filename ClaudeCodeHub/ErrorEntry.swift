//
//  ErrorEntry.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import Foundation
import SwiftData

@Model
final class ErrorEntry {
    var id: UUID
    var errorText: String
    var generatedPrompt: String
    var timestamp: Date
    var isBookmarked: Bool
    
    init(errorText: String, generatedPrompt: String, isBookmarked: Bool = false) {
        self.id = UUID()
        self.errorText = errorText
        self.generatedPrompt = generatedPrompt
        self.timestamp = Date()
        self.isBookmarked = isBookmarked
    }
}