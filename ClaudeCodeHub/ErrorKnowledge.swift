//
//  ErrorKnowledge.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import Foundation
import SwiftData

@Model
final class KnownError {
    var id: UUID
    var title: String
    var errorMessage: String
    var category: ErrorCategory
    var solution: String
    var codeExample: String
    var tags: [String]
    var severity: ErrorSeverity
    var dateAdded: Date
    var isBookmarked: Bool
    
    init(title: String, errorMessage: String, category: ErrorCategory, solution: String, codeExample: String = "", tags: [String] = [], severity: ErrorSeverity = .medium) {
        self.id = UUID()
        self.title = title
        self.errorMessage = errorMessage
        self.category = category
        self.solution = solution
        self.codeExample = codeExample
        self.tags = tags
        self.severity = severity
        self.dateAdded = Date()
        self.isBookmarked = false
    }
}

enum ErrorCategory: String, CaseIterable, Codable {
    case compilation = "Compilation Errors"
    case runtime = "Runtime Errors"
    case memory = "Memory Management"
    case swiftui = "SwiftUI Errors"
    case uikit = "UIKit Errors"
    case xcode = "Xcode Build Errors"
    case autolayout = "AutoLayout Errors"
    case networking = "Networking Errors"
    case coredata = "Core Data Errors"
    case performance = "Performance Issues"
    
    var systemImage: String {
        switch self {
        case .compilation: return "hammer.fill"
        case .runtime: return "exclamationmark.triangle.fill"
        case .memory: return "memorychip.fill"
        case .swiftui: return "swift"
        case .uikit: return "iphone"
        case .xcode: return "gear.badge.xmark"
        case .autolayout: return "rectangle.stack.fill"
        case .networking: return "network"
        case .coredata: return "cylinder.fill"
        case .performance: return "speedometer"
        }
    }
}

enum ErrorSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}