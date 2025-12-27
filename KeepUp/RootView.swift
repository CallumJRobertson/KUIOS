import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    init() {
        // Customize Tab Bar Appearance to match the dark theme
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.9)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            
            YourUpdateView()
                .tabItem {
                    Label("Updates", systemImage: "sparkles.tv")
                }
                .tag(0)
            
            // Removed the dedicated "Search" tab — search is now available from the Updates toolbar.
            
            // Renamed from "Tracked" to "Library"
            TrackedListView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.purple)
    }
}
