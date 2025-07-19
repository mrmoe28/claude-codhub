//
//  KnowledgeBaseView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import SwiftData

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var knownErrors: [KnownError]
    @State private var searchText = ""
    @State private var selectedCategory: ErrorCategory? = nil
    @State private var selectedSeverity: ErrorSeverity? = nil
    @State private var showingDetail = false
    @State private var selectedError: KnownError?
    
    private var filteredErrors: [KnownError] {
        knownErrors.filter { error in
            let matchesSearch = searchText.isEmpty || 
                error.title.localizedCaseInsensitiveContains(searchText) ||
                error.errorMessage.localizedCaseInsensitiveContains(searchText) ||
                error.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            let matchesCategory = selectedCategory == nil || error.category == selectedCategory
            let matchesSeverity = selectedSeverity == nil || error.severity == selectedSeverity
            
            return matchesSearch && matchesCategory && matchesSeverity
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    HStack {
                        CategoryFilter(selectedCategory: $selectedCategory)
                        SeverityFilter(selectedSeverity: $selectedSeverity)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Error list
                List(filteredErrors, id: \.id) { error in
                    ErrorRowView(error: error)
                        .onTapGesture {
                            selectedError = error
                            showingDetail = true
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Error Knowledge Base")
            .navigationSubtitle("\\(filteredErrors.count) known errors")
        } detail: {
            if let error = selectedError {
                ErrorDetailView(error: error)
            } else {
                VStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select an error to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Browse \\(knownErrors.count) known errors and their solutions")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if knownErrors.isEmpty {
                ErrorKnowledgeDatabase.shared.populateDatabase(context: modelContext)
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let error = selectedError {
                NavigationView {
                    ErrorDetailView(error: error)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingDetail = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search errors, solutions, or tags...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct CategoryFilter: View {
    @Binding var selectedCategory: ErrorCategory?
    
    var body: some View {
        Menu {
            Button("All Categories") {
                selectedCategory = nil
            }
            
            Divider()
            
            ForEach(ErrorCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Label(category.rawValue, systemImage: category.systemImage)
                }
            }
        } label: {
            HStack {
                Image(systemName: selectedCategory?.systemImage ?? "folder.fill")
                Text(selectedCategory?.rawValue ?? "All Categories")
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SeverityFilter: View {
    @Binding var selectedSeverity: ErrorSeverity?
    
    var body: some View {
        Menu {
            Button("All Severities") {
                selectedSeverity = nil
            }
            
            Divider()
            
            ForEach(ErrorSeverity.allCases, id: \.self) { severity in
                Button(action: { selectedSeverity = severity }) {
                    HStack {
                        Circle()
                            .fill(Color(severity.color))
                            .frame(width: 8, height: 8)
                        Text(severity.rawValue)
                    }
                }
            }
        } label: {
            HStack {
                if let severity = selectedSeverity {
                    Circle()
                        .fill(Color(severity.color))
                        .frame(width: 8, height: 8)
                }
                Text(selectedSeverity?.rawValue ?? "All Severities")
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ErrorRowView: View {
    let error: KnownError
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: error.category.systemImage)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(error.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Circle()
                    .fill(Color(error.severity.color))
                    .frame(width: 8, height: 8)
            }
            
            Text(error.errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(error.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                if error.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ErrorDetailView: View {
    let error: KnownError
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: error.category.systemImage)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        Text(error.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: toggleBookmark) {
                            Image(systemName: error.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Text(error.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        
                        Circle()
                            .fill(Color(error.severity.color))
                            .frame(width: 8, height: 8)
                        
                        Text(error.severity.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Error Message
                GroupBox("Error Message") {
                    Text(error.errorMessage)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                }
                
                // Solution
                GroupBox("Solution") {
                    Text(error.solution)
                        .textSelection(.enabled)
                        .padding()
                }
                
                // Code Example
                if !error.codeExample.isEmpty {
                    GroupBox("Code Example") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(error.codeExample)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Tags
                if !error.tags.isEmpty {
                    GroupBox("Tags") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(error.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                    }
                }
                
                // Copy Solution Button
                HStack {
                    Button(action: copySolution) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Solution")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: generateClaudePrompt) {
                        HStack {
                            Image(systemName: "wand.and.rays")
                            Text("Generate Claude Prompt")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Error Details")
    }
    
    private func toggleBookmark() {
        error.isBookmarked.toggle()
        try? modelContext.save()
    }
    
    private func copySolution() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(error.solution, forType: .string)
    }
    
    private func generateClaudePrompt() {
        let prompt = """
        🔧 **Claude Code Error Analysis Request**
        
        I'm experiencing the following error and need your expert debugging assistance:
        
        **Error Details:**
        ```
        \\(error.errorMessage)
        ```
        
        **Error Category:** \\(error.category.rawValue)
        **Severity:** \\(error.severity.rawValue)
        
        **Known Solution Reference:**
        \\(error.solution)
        
        **Please provide:**
        1. **🔍 Detailed Root Cause Analysis**
        2. **🌐 Additional Research & Alternative Solutions**
        3. **⚡ Step-by-Step Fix Instructions**
        4. **💻 Complete Code Solution**
        5. **🛡️ Enhanced Prevention Tips**
        
        **Response Format:** Please provide a comprehensive solution that builds upon the known fix above.
        
        ---
        *Generated by Claude Code Hub Knowledge Base*
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
    }
}

#Preview {
    KnowledgeBaseView()
        .modelContainer(for: [KnownError.self], inMemory: true)
}