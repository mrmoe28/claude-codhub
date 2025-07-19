//
//  EnhancedErrorFixerView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import SwiftData
import AppKit

struct EnhancedErrorFixerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var knownErrors: [KnownError]
    @Query private var errorHistory: [ErrorEntry]
    
    @AppStorage("darkMode") private var darkMode: Bool = false
    @State private var errorText: String = ""
    @State private var generatedPrompt: String = ""
    @State private var exampleFixVisible: Bool = false
    @State private var showDuplicateWarning: Bool = false
    @State private var monitoringClaude = false
    @State private var suggestedSolutions: [KnownError] = []
    @State private var showingSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Enhanced Error Fixer")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Toggle("Dark Mode", isOn: $darkMode)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: darkMode) { _, _ in
                        NSApp.appearance = darkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
                    }
            }
            .padding(.bottom, 8)
            
            // Instructions
            HStack {
                Text("Paste or drag an error message below to get AI-powered solutions:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(knownErrors.count) known errors in database")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Error Input
            GroupBox("Error Message") {
                TextEditor(text: $errorText)
                    .frame(minHeight: 120)
                    .font(.system(.body, design: .monospaced))
                    .onDrop(of: [.plainText], isTargeted: nil) { providers in
                        providers.first?.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { item, _ in
                            if let data = item as? Data, let string = String(data: data, encoding: .utf8) {
                                DispatchQueue.main.async {
                                    errorText = string
                                    findMatchingSolutions()
                                }
                            }
                        }
                        return true
                    }
                    .onChange(of: errorText) { _, _ in
                        findMatchingSolutions()
                    }
            }
            
            // Smart Suggestions
            if !suggestedSolutions.isEmpty {
                GroupBox("💡 Smart Suggestions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Found \(suggestedSolutions.count) potential solution(s):")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(suggestedSolutions.prefix(3), id: \.id) { solution in
                                    SuggestionCard(solution: solution) {
                                        applySolution(solution)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        if suggestedSolutions.count > 3 {
                            Button("View All \(suggestedSolutions.count) Suggestions") {
                                showingSuggestions = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: generatePrompt) {
                    HStack {
                        Image(systemName: "wand.and.rays")
                        Text("Generate AI Prompt")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button(action: openClaudeCode) {
                    HStack {
                        Image(systemName: "link")
                        Text("Open Claude Code")
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: saveToHistory) {
                    HStack {
                        Image(systemName: "bookmark")
                        Text("Save to History")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(errorText.isEmpty || generatedPrompt.isEmpty)
                
                Spacer()
            }
            
            // Duplicate Warning
            if showDuplicateWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This error has been processed before. Check your history.")
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
            
            // Generated Prompt Section
            if !generatedPrompt.isEmpty {
                GroupBox("Generated Claude Prompt") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Enhanced AI prompt with knowledge base context:")
                                .font(.headline)
                            Spacer()
                            Button(action: copyPrompt) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Prompt")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        ScrollView {
                            Text(generatedPrompt)
                                .textSelection(.enabled)
                                .padding()
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            // Recent History
            if !errorHistory.isEmpty {
                GroupBox("Recent Error History") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(errorHistory.prefix(5).enumerated()), id: \.offset) { index, item in
                                HistoryRowView(entry: item) {
                                    copyHistoryPrompt(item.generatedPrompt)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
        }
        .padding()
        .onAppear {
            NSApp.appearance = darkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
            if knownErrors.isEmpty {
                ErrorKnowledgeDatabase.shared.populateDatabase(context: modelContext)
            }
        }
        .sheet(isPresented: $showingSuggestions) {
            NavigationView {
                SuggestionsListView(suggestions: suggestedSolutions) { solution in
                    applySolution(solution)
                    showingSuggestions = false
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingSuggestions = false
                        }
                    }
                }
            }
        }
    }
    
    private func findMatchingSolutions() {
        guard !errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestedSolutions = []
            return
        }
        
        suggestedSolutions = knownErrors.filter { error in
            let searchTerms = errorText.lowercased()
            return error.errorMessage.lowercased().contains(searchTerms) ||
                   error.title.lowercased().contains(searchTerms) ||
                   error.tags.contains { $0.lowercased().contains(searchTerms) } ||
                   searchTerms.contains(error.errorMessage.lowercased()) ||
                   searchTerms.contains(error.title.lowercased())
        }.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    private func applySolution(_ solution: KnownError) {
        generatedPrompt = generateEnhancedPrompt(for: errorText, withSolution: solution)
    }
    
    private func generatePrompt() {
        if let bestMatch = suggestedSolutions.first {
            generatedPrompt = generateEnhancedPrompt(for: errorText, withSolution: bestMatch)
        } else {
            generatedPrompt = generateStandardPrompt(for: errorText)
        }
        
        checkForDuplicates()
    }
    
    private func generateEnhancedPrompt(for error: String, withSolution solution: KnownError) -> String {
        return """
🔧 **Claude Code Enhanced Error Analysis Request**

I'm experiencing the following error and need your expert debugging assistance:

**Error Details:**
```
\(error)
```

**Knowledge Base Match Found:**
- **Error Type:** \(solution.category.rawValue)
- **Severity:** \(solution.severity.rawValue)
- **Known Title:** \(solution.title)

**Existing Solution Reference:**
\(solution.solution)

**Code Example from Knowledge Base:**
```swift
\(solution.codeExample)
```

**Please provide:**

1. **🔍 Enhanced Root Cause Analysis**
   - Validate the knowledge base solution against my specific error
   - Identify any unique aspects of my error case

2. **🌐 Advanced Research & Solutions**
   - Build upon the known solution with recent best practices
   - Provide alternative approaches if applicable

3. **⚡ Customized Fix**
   - Adapt the known solution to my specific context
   - Provide step-by-step implementation instructions

4. **💻 Complete Code Solution**
   - Show the corrected code with detailed comments
   - Highlight specific changes and why they work

5. **🛡️ Enhanced Prevention Tips**
   - Advanced prevention strategies beyond the basic solution
   - Modern Swift/Xcode best practices to avoid this error

**Response Format:** Please provide a comprehensive solution that enhances and builds upon the knowledge base entry above.

**Tags:** \(solution.tags.joined(separator: ", "))

---
*Generated by Claude Code Hub Enhanced Error Fixer with Knowledge Base Integration*
"""
    }
    
    private func generateStandardPrompt(for error: String) -> String {
        return """
🔧 **Claude Code Error Analysis Request**

I'm experiencing the following error and need your expert debugging assistance:

**Error Details:**
```
\(error)
```

**Please provide:**

1. **🔍 Root Cause Analysis**
   - Explain what's causing this error
   - Identify the specific problem in plain language

2. **🌐 Research & Solutions**
   - Search for similar issues and proven solutions
   - Reference official documentation when relevant

3. **⚡ Recommended Fix**
   - Provide the most effective solution
   - Explain why this approach works best

4. **💻 Code Solution**
   - Show corrected code with clear comments
   - Highlight the specific changes made

5. **🛡️ Prevention Tips**
   - Share best practices to avoid this error
   - Suggest code patterns or tools for prevention

**Response Format:** Please structure your response clearly with the corrected code and explanation ready for immediate implementation.

---
*Generated by Claude Code Hub Error Fixer*
"""
    }
    
    private func checkForDuplicates() {
        showDuplicateWarning = errorHistory.contains { $0.errorText == errorText }
    }
    
    private func saveToHistory() {
        let entry = ErrorEntry(errorText: errorText, generatedPrompt: generatedPrompt)
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    private func copyPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedPrompt, forType: .string)
    }
    
    private func copyHistoryPrompt(_ prompt: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
    }
    
    private func openClaudeCode() {
        if let url = URL(string: "https://claude.ai") {
            NSWorkspace.shared.open(url)
        }
        monitoringClaude = true
    }
}

struct SuggestionCard: View {
    let solution: KnownError
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: solution.category.systemImage)
                    .foregroundColor(.accentColor)
                
                Text(solution.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                Circle()
                    .fill(Color(solution.severity.color))
                    .frame(width: 8, height: 8)
            }
            
            Text(solution.solution.prefix(100) + "...")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Button("Apply Solution") {
                onSelect()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(width: 280, height: 140)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HistoryRowView: View {
    let entry: ErrorEntry
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.errorText.prefix(60) + (entry.errorText.count > 60 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(1)
                
                Text(entry.timestamp, format: .dateTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct SuggestionsListView: View {
    let suggestions: [KnownError]
    let onSelect: (KnownError) -> Void
    
    var body: some View {
        List(suggestions, id: \.id) { suggestion in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: suggestion.category.systemImage)
                        .foregroundColor(.accentColor)
                    
                    Text(suggestion.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(suggestion.severity.color))
                        .frame(width: 8, height: 8)
                    
                    Text(suggestion.severity.rawValue)
                        .font(.caption)
                }
                
                Text(suggestion.solution)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Button("Apply This Solution") {
                    onSelect(suggestion)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("All Suggestions")
    }
}

#Preview {
    EnhancedErrorFixerView()
        .modelContainer(for: [KnownError.self, ErrorEntry.self], inMemory: true)
}