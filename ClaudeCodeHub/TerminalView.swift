//
//  TerminalView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import Foundation

struct TerminalView: NSViewRepresentable {
    @Binding var isVisible: Bool
    @Binding var terminalOutput: String
    @State private var process: Process?
    @State private var outputPipe: Pipe?
    
    let onTerminalReady: (() -> Void)?
    
    init(isVisible: Binding<Bool>, terminalOutput: Binding<String>, onTerminalReady: (() -> Void)? = nil) {
        self._isVisible = isVisible
        self._terminalOutput = terminalOutput
        self.onTerminalReady = onTerminalReady
    }
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.cgColor
        containerView.layer?.borderColor = NSColor.gray.cgColor
        containerView.layer?.borderWidth = 1
        containerView.layer?.cornerRadius = 8
        
        // Create terminal text view
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure text view for terminal appearance
        textView.backgroundColor = NSColor.black
        textView.textColor = NSColor.green
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isRichText = false
        textView.string = "Terminal Ready...\n"
        
        // Set up scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        
        // Add to container
        containerView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        // Store references for updates
        containerView.identifier = NSUserInterfaceItemIdentifier("TerminalContainer")
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update visibility
        nsView.isHidden = !isVisible
        
        // Update terminal content if needed
        if let scrollView = nsView.subviews.first as? NSScrollView,
           let textView = scrollView.documentView as? NSTextView {
            
            if textView.string != terminalOutput {
                textView.string = terminalOutput
                
                // Auto-scroll to bottom
                DispatchQueue.main.async {
                    textView.scrollToEndOfDocument(nil)
                }
            }
        }
    }
}

class TerminalManager: ObservableObject {
    @Published var terminalOutput: String = ""
    @Published var isTerminalVisible: Bool = false
    @Published var isProcessRunning: Bool = false
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    func startClaudeTerminal() {
        guard !isProcessRunning else { return }
        
        setupTerminal()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.executeCommand("claude")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.handleClaudeStartup()
        }
    }
    
    private func setupTerminal() {
        isTerminalVisible = true
        terminalOutput = "🚀 Starting Claude Code Terminal...\n"
        appendOutput("$ Initializing terminal session...")
        appendOutput("$ Opening Terminal.app...")
        
        isProcessRunning = true
    }
    
    private func executeCommand(_ command: String) {
        appendOutput("$ \(command)")
        
        // Simulate terminal commands for demo
        switch command {
        case "claude":
            appendOutput("✅ Opening Claude Code terminal...")
            appendOutput("🔄 Connecting to Claude AI...")
            appendOutput("📝 Ready for error analysis!")
            
        default:
            appendOutput("Command executed: \(command)")
        }
    }
    
    private func handleClaudeStartup() {
        appendOutput("🎯 Claude terminal is ready!")
        appendOutput("💡 Paste your error above to get AI-powered solutions")
        appendOutput("🤖 Integration with DesktopCommander MCP active")
        appendOutput("───────────────────────────────────")
    }
    
    func executeDesktopCommand(_ command: String) {
        appendOutput("🖥️  DesktopCommander: \(command)")
        
        // Here we'll integrate with DesktopCommander MCP
        switch command {
        case "start_process":
            appendOutput("✅ Terminal process started")
            appendOutput("🔗 Connected to local shell")
            
        case "open_claude":
            appendOutput("🌐 Opening Claude AI interface...")
            appendOutput("⏳ Waiting for Claude to load...")
            appendOutput("✨ Claude ready for interaction!")
            
        default:
            appendOutput("📋 Executing: \(command)")
        }
    }
    
    private func appendOutput(_ text: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.terminalTimestamp.string(from: Date())
            self.terminalOutput += "[\(timestamp)] \(text)\n"
        }
    }
    
    func clearTerminal() {
        terminalOutput = "Terminal cleared.\n"
    }
    
    func stopTerminal() {
        process?.terminate()
        process = nil
        isProcessRunning = false
        isTerminalVisible = false
        terminalOutput = ""
    }
}

extension DateFormatter {
    static let terminalTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

// MARK: - Responsive Terminal Canvas
struct ResponsiveTerminalCanvas: View {
    @StateObject private var terminalManager = TerminalManager()
    @Binding var errorText: String
    @State private var canvasSize: CGSize = .zero
    @State private var terminalFrame: CGRect = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main canvas background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(spacing: 0) {
                    // Error message area (top half)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Error Message Input")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if terminalManager.isTerminalVisible {
                                Button(action: {
                                    terminalManager.clearTerminal()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.borderless)
                                .help("Clear Terminal")
                            }
                        }
                        
                        TextEditor(text: $errorText)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .frame(height: terminalManager.isTerminalVisible ? geometry.size.height * 0.4 : geometry.size.height * 0.8)
                    .padding()
                    
                    // Terminal area (bottom half - appears when active)
                    if terminalManager.isTerminalVisible {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "terminal")
                                    .foregroundColor(.green)
                                Text("Claude Terminal")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if terminalManager.isProcessRunning {
                                    HStack {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    HStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                        Text("Disconnected")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Button(action: {
                                    terminalManager.stopTerminal()
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                                .help("Close Terminal")
                            }
                            
                            TerminalView(
                                isVisible: $terminalManager.isTerminalVisible,
                                terminalOutput: $terminalManager.terminalOutput
                            )
                            .frame(height: geometry.size.height * 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onAppear {
                canvasSize = geometry.size
            }
            .onChange(of: geometry.size) { _, newSize in
                canvasSize = newSize
                updateLayout()
            }
        }
        .environmentObject(terminalManager)
    }
    
    private func updateLayout() {
        // Update terminal frame based on canvas size
        let terminalHeight = terminalManager.isTerminalVisible ? canvasSize.height * 0.5 : 0
        terminalFrame = CGRect(
            x: 8,
            y: canvasSize.height - terminalHeight - 8,
            width: canvasSize.width - 16,
            height: terminalHeight
        )
    }
}

// MARK: - Enhanced Error Fixer with Terminal Integration
struct TerminalIntegratedErrorFixer: View {
    @State private var errorText: String = ""
    @StateObject private var terminalManager = TerminalManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with terminal controls
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Terminal-Integrated Error Fixer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    openClaudeWithTerminal()
                }) {
                    HStack {
                        Image(systemName: "terminal")
                        Text("Open Claude Terminal")
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    executeDesktopCommands()
                }) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                        Text("Desktop Commander")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // Responsive terminal canvas
            ResponsiveTerminalCanvas(errorText: $errorText)
                .frame(minHeight: 400)
            
            // Terminal control buttons
            if terminalManager.isTerminalVisible {
                HStack {
                    Button("Execute in Terminal") {
                        terminalManager.executeDesktopCommand("execute_error_fix")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Send to Claude") {
                        terminalManager.executeDesktopCommand("send_to_claude")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Auto-fix Error") {
                        terminalManager.executeDesktopCommand("auto_fix_error")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .environmentObject(terminalManager)
    }
    
    private func openClaudeWithTerminal() {
        // Step 1: Start terminal automation
        terminalManager.startClaudeTerminal()
        
        // Step 2: Use DesktopCommander to open terminal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            terminalManager.executeDesktopCommand("start_process")
        }
        
        // Step 3: Type "claude" and hit enter
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            terminalManager.executeDesktopCommand("open_claude")
        }
        
        // Step 4: Handle Claude startup and "yes" confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            terminalManager.executeDesktopCommand("confirm_claude_startup")
        }
    }
    
    private func executeDesktopCommands() {
        // Integration with DesktopCommander MCP
        terminalManager.executeDesktopCommand("desktop_commander_init")
        
        // Example DesktopCommander commands
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            terminalManager.executeDesktopCommand("list_processes")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            terminalManager.executeDesktopCommand("interact_with_process")
        }
    }
}

#Preview {
    TerminalIntegratedErrorFixer()
        .frame(width: 800, height: 600)
}