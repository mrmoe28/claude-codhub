//
//  SidebarView.swift
//  ClaudeCodeHub
//
//  Created by Claude Code on 7/18/25.
//

import SwiftUI

struct SidebarView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        List(AppState.AppView.allCases, id: \.self, selection: $appState.selectedView) { view in
            NavigationLink(value: view) {
                Label(view.rawValue, systemImage: view.systemImage)
            }
        }
        .navigationTitle("Claude Code Hub")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.showingSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(appState: AppState())
    } detail: {
        Text("Detail View")
    }
}