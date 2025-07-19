//
//  ErrorKnowledgeDatabase.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import Foundation
import SwiftData

class ErrorKnowledgeDatabase {
    static let shared = ErrorKnowledgeDatabase()
    
    private init() {}
    
    func populateDatabase(context: ModelContext) {
        let existingErrors = try? context.fetch(FetchDescriptor<KnownError>())
        if let errors = existingErrors, !errors.isEmpty {
            return // Database already populated
        }
        
        let knownErrors = createKnownErrors()
        for error in knownErrors {
            context.insert(error)
        }
        
        try? context.save()
    }
    
    private func createKnownErrors() -> [KnownError] {
        return [
            // MARK: - Compilation Errors
            KnownError(
                title: "Command CompileSwift failed with a nonzero exit code",
                errorMessage: "Command CompileSwift failed with a nonzero exit code",
                category: .compilation,
                solution: "1. Change Compilation Mode from Incremental to Whole Module in Build Settings\n2. Clean build folder (Shift+Cmd+K) and delete derived data\n3. Run 'pod install --repo-update' if using CocoaPods\n4. Check for syntax errors in your Swift files",
                codeExample: """
                // In Build Settings, search for SWIFT_COMPILATION_MODE
                // Change from "Incremental" to "Whole Module" for Release
                """,
                tags: ["xcode", "swift", "compilation", "build"],
                severity: .high
            ),
            
            KnownError(
                title: "Use of unresolved identifier",
                errorMessage: "Use of unresolved identifier 'variableName'",
                category: .compilation,
                solution: "1. Check if the variable/function is declared in the current scope\n2. Verify correct spelling and capitalization\n3. Ensure imports are correct\n4. Check if the identifier is declared in a different file",
                codeExample: """
                // Error: Use of unresolved identifier 'myVariable'
                print(myVariable)
                
                // Fix: Declare the variable first
                let myVariable = "Hello World"
                print(myVariable)
                """,
                tags: ["swift", "identifier", "scope"],
                severity: .medium
            ),
            
            KnownError(
                title: "No such module found",
                errorMessage: "No such module 'ModuleName'",
                category: .xcode,
                solution: "1. Open .xcworkspace file instead of .xcodeproj when using CocoaPods\n2. Ensure all deployment targets match\n3. Add 'use_frameworks!' to Podfile for Swift\n4. Run 'pod update' and clean build\n5. Check Framework Search Paths in Build Settings",
                codeExample: """
                // In Podfile, ensure you have:
                use_frameworks!
                
                target 'YourApp' do
                  pod 'SomeFramework'
                end
                """,
                tags: ["xcode", "module", "cocoapods", "framework"],
                severity: .high
            ),
            
            // MARK: - Runtime Errors
            KnownError(
                title: "Unexpectedly found nil while unwrapping an optional value",
                errorMessage: "Fatal error: Unexpectedly found nil while unwrapping an optional value",
                category: .runtime,
                solution: "1. Use optional binding (if let) instead of force unwrapping\n2. Use nil-coalescing operator (??)\n3. Check if the value is nil before force unwrapping\n4. Use guard statements for early exit",
                codeExample: """
                // Error: Force unwrapping nil value
                let text: String? = nil
                print(text!) // Crash!
                
                // Fix 1: Optional binding
                if let text = text {
                    print(text)
                }
                
                // Fix 2: Nil-coalescing
                print(text ?? "Default value")
                
                // Fix 3: Guard statement
                guard let text = text else { return }
                print(text)
                """,
                tags: ["swift", "optional", "nil", "crash"],
                severity: .critical
            ),
            
            KnownError(
                title: "Index out of range",
                errorMessage: "Fatal error: Index out of range",
                category: .runtime,
                solution: "1. Check array bounds before accessing elements\n2. Use safe array access methods\n3. Validate indices before using them\n4. Use optional subscripting for safe access",
                codeExample: """
                let array = [1, 2, 3]
                
                // Error: Index out of range
                print(array[5]) // Crash!
                
                // Fix 1: Check bounds
                if array.indices.contains(5) {
                    print(array[5])
                }
                
                // Fix 2: Safe access extension
                extension Array {
                    subscript(safe index: Int) -> Element? {
                        return indices.contains(index) ? self[index] : nil
                    }
                }
                print(array[safe: 5] ?? "Index out of range")
                """,
                tags: ["swift", "array", "index", "bounds"],
                severity: .high
            ),
            
            // MARK: - Memory Management
            KnownError(
                title: "Strong reference cycle with closures",
                errorMessage: "Memory leak due to retain cycle",
                category: .memory,
                solution: "1. Use [weak self] or [unowned self] in closure capture lists\n2. Break the cycle by setting references to nil\n3. Use weak references for delegates\n4. Avoid capturing self strongly in closures",
                codeExample: """
                class ViewController: UIViewController {
                    var completion: (() -> Void)?
                    
                    // Error: Strong reference cycle
                    func setupBadClosure() {
                        completion = {
                            self.view.backgroundColor = .red // Strong capture of self
                        }
                    }
                    
                    // Fix: Use weak self
                    func setupGoodClosure() {
                        completion = { [weak self] in
                            self?.view.backgroundColor = .red
                        }
                    }
                }
                """,
                tags: ["memory", "retain-cycle", "closure", "weak"],
                severity: .high
            ),
            
            KnownError(
                title: "Delegate retain cycle",
                errorMessage: "Memory leak in delegate pattern",
                category: .memory,
                solution: "1. Always declare delegate properties as weak\n2. Use weak references to avoid retain cycles\n3. Set delegates to nil in deinit if needed",
                codeExample: """
                protocol MyDelegate: AnyObject {
                    func didSomething()
                }
                
                class MyClass {
                    // Error: Strong delegate reference
                    var delegate: MyDelegate?
                    
                    // Fix: Weak delegate reference
                    weak var delegate: MyDelegate?
                }
                """,
                tags: ["memory", "delegate", "weak", "retain-cycle"],
                severity: .medium
            ),
            
            // MARK: - SwiftUI Errors
            KnownError(
                title: "State modification during view computation",
                errorMessage: "Modifying state during view update can cause undefined behavior",
                category: .swiftui,
                solution: "1. Use .onChange() modifier instead of property observers\n2. Avoid modifying @State during body computation\n3. Use .onAppear() for initial setup\n4. Move state changes to proper lifecycle methods",
                codeExample: """
                struct MyView: View {
                    @State private var counter = 0
                    
                    var body: some View {
                        Text("Count: \\(counter)")
                            // Fix: Use onChange instead of modifying state in body
                            .onChange(of: counter) { _, newValue in
                                // Handle state change here
                            }
                            .onAppear {
                                // Initialize state here
                                counter = 1
                            }
                    }
                }
                """,
                tags: ["swiftui", "state", "view-update", "lifecycle"],
                severity: .medium
            ),
            
            KnownError(
                title: "EnvironmentObject not found",
                errorMessage: "Fatal error: No ObservableObject of type found",
                category: .swiftui,
                solution: "1. Ensure the EnvironmentObject is provided higher in the view hierarchy\n2. Use .environmentObject() modifier on parent views\n3. Check that the object type matches exactly\n4. Verify the object is created before the view",
                codeExample: """
                @Observable
                class AppData {
                    var value: String = ""
                }
                
                struct ParentView: View {
                    let appData = AppData()
                    
                    var body: some View {
                        ChildView()
                            .environmentObject(appData) // Provide the object
                    }
                }
                
                struct ChildView: View {
                    @EnvironmentObject var appData: AppData
                    
                    var body: some View {
                        Text(appData.value)
                    }
                }
                """,
                tags: ["swiftui", "environment", "observable"],
                severity: .high
            ),
            
            // MARK: - AutoLayout Errors
            KnownError(
                title: "Constraint conflicts in AutoLayout",
                errorMessage: "Unable to simultaneously satisfy constraints",
                category: .autolayout,
                solution: "1. Check for conflicting constraints\n2. Set constraint priorities\n3. Remove redundant constraints\n4. Use layout guides instead of direct constraints\n5. Debug with view hierarchy debugger",
                codeExample: """
                // Error: Conflicting constraints
                view.widthAnchor.constraint(equalToConstant: 100).isActive = true
                view.widthAnchor.constraint(equalToConstant: 200).isActive = true
                
                // Fix: Remove conflicting constraint or set priority
                let constraint1 = view.widthAnchor.constraint(equalToConstant: 100)
                constraint1.priority = UILayoutPriority(999)
                constraint1.isActive = true
                
                let constraint2 = view.widthAnchor.constraint(equalToConstant: 200)
                constraint2.priority = UILayoutPriority(750)
                constraint2.isActive = true
                """,
                tags: ["autolayout", "constraints", "uikit"],
                severity: .medium
            ),
            
            KnownError(
                title: "Constraint anchor in different view hierarchy",
                errorMessage: "Constraint anchor in different view hierarchy",
                category: .autolayout,
                solution: "1. Ensure views are added to the same view hierarchy before constraining\n2. Add subviews before creating constraints\n3. Use safe area layout guides\n4. Check view controller lifecycle timing",
                codeExample: """
                // Error: Creating constraints before adding to hierarchy
                let subview = UIView()
                subview.translatesAutoresizingMaskIntoConstraints = false
                subview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true // Error!
                view.addSubview(subview)
                
                // Fix: Add to hierarchy first
                let subview = UIView()
                subview.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(subview) // Add first
                subview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                """,
                tags: ["autolayout", "hierarchy", "constraints"],
                severity: .high
            ),
            
            // MARK: - Xcode Build Errors
            KnownError(
                title: "Framework not found",
                errorMessage: "Framework not found",
                category: .xcode,
                solution: "1. Check Framework Search Paths in Build Settings\n2. Ensure framework is added to target\n3. Verify framework is in the correct location\n4. Clean build and derived data\n5. Check deployment target compatibility",
                codeExample: """
                // In Build Settings, set Framework Search Paths to:
                $(SRCROOT) // For frameworks in project directory
                $(inherited) // Inherit from project
                """,
                tags: ["xcode", "framework", "build-settings"],
                severity: .high
            ),
            
            KnownError(
                title: "Build Active Architecture Only",
                errorMessage: "Archive fails but build succeeds",
                category: .xcode,
                solution: "1. Set 'Build Active Architecture Only' to NO for Release configuration\n2. Ensure all architectures are supported\n3. Clean build folder before archiving\n4. Check scheme settings for Archive",
                codeExample: """
                // In Build Settings:
                // Debug: Build Active Architecture Only = YES
                // Release: Build Active Architecture Only = NO
                """,
                tags: ["xcode", "archive", "architecture"],
                severity: .medium
            ),
            
            // MARK: - Additional Common Errors
            KnownError(
                title: "This class is not key value coding-compliant",
                errorMessage: "This class is not key value coding-compliant for the key",
                category: .uikit,
                solution: "1. Check Storyboard connections for deleted outlets\n2. Remove broken IBOutlet connections\n3. Ensure outlet names match in code and storyboard\n4. Clean and rebuild project",
                codeExample: """
                // Remove broken @IBOutlet connections:
                @IBOutlet weak var deletedButton: UIButton! // Remove this if button deleted
                
                // Or reconnect in storyboard:
                @IBOutlet weak var myButton: UIButton!
                """,
                tags: ["uikit", "storyboard", "iboutlet"],
                severity: .medium
            ),
            
            KnownError(
                title: "Property wrapper confusion",
                errorMessage: "State/StateObject/ObservedObject used incorrectly",
                category: .swiftui,
                solution: "1. Use @State for value types owned by the view\n2. Use @StateObject for creating ObservableObject instances\n3. Use @ObservedObject for objects passed from parent\n4. Use @Binding for two-way data flow",
                codeExample: """
                struct ParentView: View {
                    @StateObject private var data = MyData() // Create object here
                    
                    var body: some View {
                        ChildView(data: data)
                    }
                }
                
                struct ChildView: View {
                    @ObservedObject var data: MyData // Receive object
                    
                    var body: some View {
                        Text(data.value)
                    }
                }
                """,
                tags: ["swiftui", "state", "observable", "binding"],
                severity: .medium
            ),
            
            KnownError(
                title: "Timer retain cycle",
                errorMessage: "Timer causing memory leak",
                category: .memory,
                solution: "1. Invalidate timers in deinit\n2. Use weak references in timer targets\n3. Consider using Timer.scheduledTimer with weak self\n4. Store timer references to invalidate later",
                codeExample: """
                class MyClass {
                    private var timer: Timer?
                    
                    func startTimer() {
                        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                            self?.timerFired()
                        }
                    }
                    
                    func stopTimer() {
                        timer?.invalidate()
                        timer = nil
                    }
                    
                    deinit {
                        stopTimer()
                    }
                    
                    private func timerFired() {
                        // Timer logic here
                    }
                }
                """,
                tags: ["memory", "timer", "retain-cycle"],
                severity: .medium
            ),
            
            KnownError(
                title: "SwiftUI NavigationLink issues",
                errorMessage: "NavigationLink not working or causing crashes",
                category: .swiftui,
                solution: "1. Ensure NavigationView/NavigationStack is present\n2. Use proper NavigationLink initialization\n3. Check destination view initialization\n4. Avoid nested NavigationViews",
                codeExample: """
                struct ContentView: View {
                    var body: some View {
                        NavigationView {
                            List {
                                NavigationLink("Go to Detail") {
                                    DetailView()
                                }
                            }
                            .navigationTitle("Main")
                        }
                    }
                }
                
                struct DetailView: View {
                    var body: some View {
                        Text("Detail View")
                            .navigationTitle("Detail")
                    }
                }
                """,
                tags: ["swiftui", "navigation", "navigationlink"],
                severity: .medium
            )
        ]
    }
}