//
//  ContentView.swift
//  ClaudeCodeHub
//
//  Created by Edward Harrison on 7/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var appState = AppState()

    var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            Group {
                switch appState.selectedView {
                case .errorFixer:
                    IntegratedErrorFixerView()
                case .terminals:
                    MultiTerminalView()
                case .history:
                    KnowledgeBaseView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .onChange(of: appState.isDarkMode) { _, _ in
            appState.updateAppearance()
        }
        .onAppear {
            appState.updateAppearance()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
