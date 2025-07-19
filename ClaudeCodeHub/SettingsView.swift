//
//  SettingsView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var knownErrors: [KnownError]
    @Query private var errorHistory: [ErrorEntry]
    
    @AppStorage("darkMode") private var darkMode: Bool = false
    @AppStorage("autoSaveErrors") private var autoSaveErrors: Bool = true
    @AppStorage("showSuggestions") private var showSuggestions: Bool = true
    @AppStorage("maxHistoryItems") private var maxHistoryItems: Int = 50
    
    @State private var showingClearHistoryAlert = false
    @State private var showingResetDatabaseAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Appearance Settings
                    GroupBox("Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Dark Mode", isOn: $darkMode)
                                .onChange(of: darkMode) { _, _ in
                                    NSApp.appearance = darkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
                                }
                        }
                        .padding()
                    }
                    
                    // Error Fixer Settings
                    GroupBox("Error Fixer") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Auto-save processed errors", isOn: $autoSaveErrors)
                            Toggle("Show smart suggestions", isOn: $showSuggestions)
                            
                            HStack {
                                Text("Max history items:")
                                Spacer()
                                Stepper(value: $maxHistoryItems, in: 10...200, step: 10) {
                                    Text("\(maxHistoryItems)")
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Database Statistics
                    GroupBox("Knowledge Base Statistics") {
                        VStack(alignment: .leading, spacing: 8) {
                            StatRow(label: "Known Errors", value: "\(knownErrors.count)")
                            StatRow(label: "Error History", value: "\(errorHistory.count)")
                            StatRow(label: "Bookmarked Errors", value: "\(knownErrors.filter(\.isBookmarked).count)")
                            
                            let categoryStats = Dictionary(grouping: knownErrors, by: \.category)
                            ForEach(ErrorCategory.allCases, id: \.self) { category in
                                if let count = categoryStats[category]?.count, count > 0 {
                                    StatRow(label: category.rawValue, value: "\(count)")
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Data Management
                    GroupBox("Data Management") {
                        VStack(spacing: 12) {
                            Button(action: { showingClearHistoryAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Error History")
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.orange)
                            
                            Button(action: { showingResetDatabaseAlert = true }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reset Knowledge Base")
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            
                            Button(action: exportData) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Data")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                    
                    // About
                    GroupBox("About") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Claude Code Hub")
                                .font(.headline)
                            Text("Enhanced Error Fixing with AI Knowledge Base")
                                .foregroundColor(.secondary)
                            Text("Version 2.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            Text("Features:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• 50+ Known Swift/Xcode errors with solutions")
                                Text("• AI-powered error matching and suggestions")
                                Text("• Enhanced Claude prompt generation")
                                Text("• Error history and bookmarking")
                                Text("• Modern SwiftUI architecture")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .alert("Clear History", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearHistory()
            }
        } message: {
            Text("This will permanently delete all error history. This action cannot be undone.")
        }
        .alert("Reset Knowledge Base", isPresented: $showingResetDatabaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetKnowledgeBase()
            }
        } message: {
            Text("This will reset the knowledge base to default and re-populate with 50+ known errors. Custom entries will be lost.")
        }
    }
    
    private func clearHistory() {
        for entry in errorHistory {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    private func resetKnowledgeBase() {
        for error in knownErrors {
            modelContext.delete(error)
        }
        try? modelContext.save()
        
        ErrorKnowledgeDatabase.shared.populateDatabase(context: modelContext)
    }
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ClaudeCodeHub_Export.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                exportDataToFile(url: url)
            }
        }
    }
    
    private func exportDataToFile(url: URL) {
        let exportData = ExportData(
            knownErrors: knownErrors.map { ExportKnownError(from: $0) },
            errorHistory: errorHistory.map { ExportErrorEntry(from: $0) }
        )
        
        do {
            let data = try JSONEncoder().encode(exportData)
            try data.write(to: url)
        } catch {
            print("Export failed: \(error)")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
}

struct ExportData: Codable {
    let knownErrors: [ExportKnownError]
    let errorHistory: [ExportErrorEntry]
}

struct ExportKnownError: Codable {
    let title: String
    let errorMessage: String
    let category: String
    let solution: String
    let codeExample: String
    let tags: [String]
    let severity: String
    let isBookmarked: Bool
    
    init(from knownError: KnownError) {
        self.title = knownError.title
        self.errorMessage = knownError.errorMessage
        self.category = knownError.category.rawValue
        self.solution = knownError.solution
        self.codeExample = knownError.codeExample
        self.tags = knownError.tags
        self.severity = knownError.severity.rawValue
        self.isBookmarked = knownError.isBookmarked
    }
}

struct ExportErrorEntry: Codable {
    let errorText: String
    let generatedPrompt: String
    let timestamp: Date
    let isBookmarked: Bool
    
    init(from errorEntry: ErrorEntry) {
        self.errorText = errorEntry.errorText
        self.generatedPrompt = errorEntry.generatedPrompt
        self.timestamp = errorEntry.timestamp
        self.isBookmarked = errorEntry.isBookmarked
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [KnownError.self, ErrorEntry.self], inMemory: true)
}