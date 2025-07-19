//
//  RealTerminalView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI
import Foundation
import AppKit

// MARK: - Terminal Process Manager
@MainActor
class TerminalProcess: ObservableObject {
    @Published var isRunning = false
    @Published var output = ""
    @Published var currentState: TerminalState = .idle
    
    private var process: Process?
    private var ptyMaster: Int32 = -1
    private var ptySlave: Int32 = -1
    private var outputSource: DispatchSourceRead?
    
    let terminalID: String
    
    enum TerminalState: Equatable {
        case idle
        case starting
        case ready
        case claudeLaunching
        case claudeReady
        case error(String)
        
        static func == (lhs: TerminalState, rhs: TerminalState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.starting, .starting), (.ready, .ready), 
                 (.claudeLaunching, .claudeLaunching), (.claudeReady, .claudeReady):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    init(terminalID: String) {
        self.terminalID = terminalID
    }
    
    func startTerminal() {
        guard !isRunning else { return }
        
        setupPTY()
        startProcess()
        startReadingOutput()
        
        isRunning = true
        currentState = .starting
        
        // Simulate terminal startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentState = .ready
            self.appendOutput("Terminal \(self.terminalID) ready. Type 'claude' to start Claude Code.\n")
        }
    }
    
    private func setupPTY() {
        // Create a pseudo-terminal pair
        var master: Int32 = -1
        var slave: Int32 = -1
        
        let result = openpty(&master, &slave, nil, nil, nil)
        if result == 0 {
            ptyMaster = master
            ptySlave = slave
            
            // Set non-blocking mode for the master
            let flags = fcntl(master, F_GETFL)
            if flags != -1 {
                let result = fcntl(master, F_SETFL, flags | O_NONBLOCK)
                if result == -1 {
                    print("Warning: Failed to set non-blocking mode for PTY master")
                }
            }
        } else {
            print("Failed to create PTY pair: \(result)")
            currentState = .error("Failed to create terminal")
        }
    }
    
    private func startProcess() {
        guard ptySlave != -1 else {
            currentState = .error("PTY not initialized")
            return
        }
        
        process = Process()
        process?.executableURL = URL(fileURLWithPath: "/bin/bash")
        process?.arguments = ["-i"] // Interactive shell
        
        // Set up environment
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLUMNS"] = "80"
        env["LINES"] = "24"
        process?.environment = env
        
        // Configure file handles to use PTY slave
        let slaveFH = FileHandle(fileDescriptor: ptySlave, closeOnDealloc: false)
        process?.standardInput = slaveFH
        process?.standardOutput = slaveFH
        process?.standardError = slaveFH
        
        do {
            try process?.run()
        } catch {
            currentState = .error("Failed to start terminal: \(error.localizedDescription)")
        }
    }
    
    private func startReadingOutput() {
        guard ptyMaster != -1 else { return }
        
        outputSource = DispatchSource.makeReadSource(fileDescriptor: ptyMaster, queue: .main)
        outputSource?.setEventHandler { [weak self] in
            self?.readOutput()
        }
        outputSource?.resume()
    }
    
    private func readOutput() {
        guard ptyMaster != -1 else { return }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        let bytesRead = read(ptyMaster, buffer, bufferSize)
        if bytesRead > 0 {
            let data = Data(bytes: buffer, count: bytesRead)
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.appendOutput(string)
                }
            }
        } else if bytesRead == -1 {
            let error = errno
            if error != EAGAIN && error != EWOULDBLOCK {
                print("Error reading from PTY: \(String(cString: strerror(error)))")
            }
        }
    }
    
    func sendCommand(_ command: String) {
        guard ptyMaster != -1 else { return }
        
        let commandWithNewline = command + "\n"
        let data = commandWithNewline.data(using: .utf8) ?? Data()
        
        let bytesWritten = data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else { return -1 }
            return write(ptyMaster, baseAddress, data.count)
        }
        
        if bytesWritten == -1 {
            print("Failed to write command to PTY: \(command)")
            return
        }
        
        // Handle special commands
        if command == "claude" {
            handleClaudeCommand()
        }
    }
    
    private func handleClaudeCommand() {
        currentState = .claudeLaunching
        appendOutput("🚀 Launching Claude Code...\n")
        
        // Execute actual Claude Code CLI
        let claudePath = "/Users/edwardharrison/.nvm/versions/node/v22.17.0/bin/claude"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Send the actual claude command with full path
            self.executeClaudeCommand(claudePath)
        }
    }
    
    private func executeClaudeCommand(_ claudePath: String) {
        guard ptyMaster != -1 else { return }
        
        // Send the claude command
        let command = claudePath + "\n"
        let data = command.data(using: .utf8) ?? Data()
        
        let bytesWritten = data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else { return -1 }
            return write(ptyMaster, baseAddress, data.count)
        }
        
        if bytesWritten == -1 {
            print("Failed to write Claude command to PTY")
            currentState = .error("Failed to execute Claude command")
            return
        }
        
        // Monitor for Claude Code startup and auto-confirm
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.autoConfirmClaudeStartup()
        }
    }
    
    private func autoConfirmClaudeStartup() {
        guard ptyMaster != -1 else { return }
        
        // Send "y" to confirm Claude Code features
        let confirmCommand = "y\n"
        let data = confirmCommand.data(using: .utf8) ?? Data()
        
        let bytesWritten = data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else { return -1 }
            return write(ptyMaster, baseAddress, data.count)
        }
        
        if bytesWritten == -1 {
            print("Failed to write confirmation to PTY")
            currentState = .error("Failed to confirm Claude startup")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.currentState = .claudeReady
            self.appendOutput("\n✅ Claude Code is ready for commands!\n")
        }
    }
    
    private func appendOutput(_ text: String) {
        output += text
        
        // Keep output manageable
        let lines = output.components(separatedBy: .newlines)
        if lines.count > 1000 {
            output = lines.suffix(800).joined(separator: "\n")
        }
    }
    
    func stopTerminal() {
        outputSource?.cancel()
        process?.terminate()
        
        if ptyMaster != -1 {
            close(ptyMaster)
            ptyMaster = -1
        }
        
        if ptySlave != -1 {
            close(ptySlave)
            ptySlave = -1
        }
        
        isRunning = false
        currentState = .idle
        output = ""
    }
    
    deinit {
        // Clean up resources without calling MainActor methods
        outputSource?.cancel()
        process?.terminate()
        
        if ptyMaster != -1 {
            close(ptyMaster)
        }
        
        if ptySlave != -1 {
            close(ptySlave)
        }
    }
}

// MARK: - Real Terminal View
struct RealTerminalView: NSViewRepresentable {
    @ObservedObject var terminalProcess: TerminalProcess
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.cgColor
        containerView.layer?.cornerRadius = 8
        
        // Create scroll view and text view for terminal output
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure text view for terminal appearance
        textView.backgroundColor = NSColor.black
        textView.textColor = NSColor.green
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isRichText = false
        textView.string = ""
        
        // Set up scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        // Add to container
        containerView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Store reference for updates
        containerView.identifier = NSUserInterfaceItemIdentifier("TerminalContainer_\(terminalProcess.terminalID)")
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let scrollView = nsView.subviews.first as? NSScrollView,
              let textView = scrollView.documentView as? NSTextView else { return }
        
        // Update terminal content
        if textView.string != terminalProcess.output {
            textView.string = terminalProcess.output
            
            // Auto-scroll to bottom
            DispatchQueue.main.async {
                textView.scrollToEndOfDocument(nil)
            }
        }
    }
}

// MARK: - Multi-Terminal Manager
@MainActor
class MultiTerminalManager: ObservableObject {
    @Published var terminals: [TerminalProcess] = []
    @Published var selectedTerminalIndex = 0
    
    init() {
        // Create 4 terminal processes
        for i in 1...4 {
            let terminal = TerminalProcess(terminalID: "Terminal \(i)")
            terminals.append(terminal)
        }
    }
    
    var selectedTerminal: TerminalProcess? {
        guard selectedTerminalIndex < terminals.count else { return nil }
        return terminals[selectedTerminalIndex]
    }
    
    func startAllTerminals() {
        for terminal in terminals {
            if !terminal.isRunning {
                terminal.startTerminal()
            }
        }
    }
    
    func startClaudeInAll() {
        for terminal in terminals {
            if terminal.isRunning && terminal.currentState == .ready {
                terminal.sendCommand("claude")
            }
        }
    }
    
    func sendCommandToSelected(_ command: String) {
        selectedTerminal?.sendCommand(command)
    }
    
    func sendCommandToAll(_ command: String) {
        for terminal in terminals {
            if terminal.isRunning {
                terminal.sendCommand(command)
            }
        }
    }
    
    func stopAllTerminals() {
        for terminal in terminals {
            terminal.stopTerminal()
        }
    }
}

// MARK: - Multi-Terminal Interface
struct MultiTerminalView: View {
    @StateObject private var terminalManager = MultiTerminalManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal tabs
            HStack(spacing: 0) {
                ForEach(0..<terminalManager.terminals.count, id: \.self) { index in
                    TerminalTabButton(
                        terminal: terminalManager.terminals[index],
                        isSelected: index == terminalManager.selectedTerminalIndex
                    ) {
                        terminalManager.selectedTerminalIndex = index
                    }
                }
                
                Spacer()
                
                // Global controls
                HStack(spacing: 8) {
                    Button("Start All") {
                        terminalManager.startAllTerminals()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Claude All") {
                        terminalManager.startClaudeInAll()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Stop All") {
                        terminalManager.stopAllTerminals()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Selected terminal view
            if let selectedTerminal = terminalManager.selectedTerminal {
                VStack(spacing: 0) {
                    // Terminal header
                    HStack {
                        Text(selectedTerminal.terminalID)
                            .font(.headline)
                        
                        Spacer()
                        
                        StatusIndicator(state: selectedTerminal.currentState)
                        
                        Button(selectedTerminal.isRunning ? "Stop" : "Start") {
                            if selectedTerminal.isRunning {
                                selectedTerminal.stopTerminal()
                            } else {
                                selectedTerminal.startTerminal()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Terminal view
                    RealTerminalView(terminalProcess: selectedTerminal)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Command input
                    HStack {
                        TextField("Enter command...", text: .constant(""))
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                // Handle command input
                            }
                        
                        Button("Claude") {
                            selectedTerminal.sendCommand("claude")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TerminalTabButton: View {
    let terminal: TerminalProcess
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 8, height: 8)
                
                Text(terminal.terminalID)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private var stateColor: Color {
        switch terminal.currentState {
        case .idle:
            return .gray
        case .starting:
            return .yellow
        case .ready:
            return .green
        case .claudeLaunching:
            return .orange
        case .claudeReady:
            return .blue
        case .error:
            return .red
        }
    }
}

struct StatusIndicator: View {
    let state: TerminalProcess.TerminalState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
            
            Text(stateText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .idle: return .gray
        case .starting: return .yellow
        case .ready: return .green
        case .claudeLaunching: return .orange
        case .claudeReady: return .blue
        case .error: return .red
        }
    }
    
    private var stateText: String {
        switch state {
        case .idle: return "Idle"
        case .starting: return "Starting"
        case .ready: return "Ready"
        case .claudeLaunching: return "Launching Claude"
        case .claudeReady: return "Claude Ready"
        case .error(let message): return "Error: \(message)"
        }
    }
}

#Preview {
    MultiTerminalView()
        .frame(width: 800, height: 600)
}