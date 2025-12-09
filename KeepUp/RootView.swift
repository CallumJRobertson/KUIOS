// RootView.swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState // Access AppState
    
    var body: some View {
        // Bind selection to AppState.selectedTab
        TabView(selection: $appState.selectedTab) {
            
            YourUpdateView()
                .tabItem {
                    Label("My Update", systemImage: "clock.arrow.circlepath")
                }
                .tag(0) // ✅ Default landing tab
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1) // Target for navigation
            
            TrackedListView()
                .tabItem {
                    Label("Tracked", systemImage: "bookmark")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}
