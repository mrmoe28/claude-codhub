//
//  ErrorFixerView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import AppKit

struct ErrorFixerView: View {
    @AppStorage("darkMode") private var darkMode: Bool = false
    @State private var errorText: String = ""
    @State private var generatedPrompt: String = ""
    @State private var exampleFixVisible: Bool = false
    @State private var promptHistory: [(error: String, prompt: String)] = []
    @State private var showDuplicateWarning: Bool = false
    @State private var monitoringClaude = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Claude Code Error Fixer")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Toggle("Dark Mode", isOn: $darkMode)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: darkMode) {
                        NSApp.appearance = darkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
                    }
            }
            .padding(.bottom, 8)
            
            // Instructions
            Text("Paste or drag an error message below to generate a Claude debugging prompt:")
                .foregroundColor(.secondary)
            
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
                                }
                            }
                        }
                        return true
                    }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: generatePrompt) {
                    HStack {
                        Image(systemName: "wand.and.rays")
                        Text("Generate Prompt")
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
                
                Button(action: openAnotherClaudeTerminal) {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("New Claude Terminal")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            
            // Duplicate Warning
            if showDuplicateWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This error has already been processed.")
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
            
            // Generated Prompt Section
            if !generatedPrompt.isEmpty {
                GroupBox("Generated Claude Prompt") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ready to copy and use with Claude:")
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
                        
                        Toggle("Show Example Claude Response", isOn: $exampleFixVisible)
                        
                        if exampleFixVisible {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Example Response Format:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ScrollView {
                                    Text("**Root Cause Analysis:** This error typically occurs when...\n\n**Recommended Fix:** To resolve this issue...\n\n**Code Solution:**\n```swift\n// Corrected code here\n```\n\n**Prevention Tips:** To avoid this error in the future...")
                                        .textSelection(.enabled)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .frame(maxHeight: 120)
                            }
                        }
                    }
                }
            }
            
            // History Section
            if !promptHistory.isEmpty {
                GroupBox("Recent Error History") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(promptHistory.enumerated()), id: \.offset) { index, item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Error \(index + 1):")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Button(action: { copyHistoryPrompt(item.prompt) }) {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    
                                    Text(item.error.prefix(100) + (item.error.count > 100 ? "..." : ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    Divider()
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding()
        .onAppear {
            NSApp.appearance = darkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }
        .onChange(of: monitoringClaude) {
            if monitoringClaude {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    checkClaudeConfirmationPopups()
                }
            }
        }
    }
    
    private func generatePrompt() {
        let prompt = generateClaudePrompt(for: errorText)
        generatedPrompt = prompt
        
        if promptHistory.contains(where: { $0.error == errorText }) {
            showDuplicateWarning = true
        } else {
            showDuplicateWarning = false
            promptHistory.insert((errorText, prompt), at: 0)
            // Keep only last 10 items
            if promptHistory.count > 10 {
                promptHistory.removeLast()
            }
        }
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
    
    private func openAnotherClaudeTerminal() {
        if let url = URL(string: "https://claude.ai") {
            NSWorkspace.shared.open(url)
        }
        monitoringClaude = true
    }
    
    private func checkClaudeConfirmationPopups() {
        let script = """
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
            if frontApp contains "Safari" or frontApp contains "Chrome" then
                try
                    set theButtons to every button of every window of process frontApp
                    repeat with b in theButtons
                        if name of b contains "Yes" or name of b contains "Allow" then
                            display dialog "Claude Terminal is asking for confirmation. Please respond manually." buttons ["OK"] default button 1
                            exit repeat
                        end if
                    end repeat
                end try
            end if
        end tell
        """
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary? = nil
        appleScript?.executeAndReturnError(&errorDict)
    }
    
    private func generateClaudePrompt(for error: String) -> String {
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
}

#Preview {
    ErrorFixerView()
}