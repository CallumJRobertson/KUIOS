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
            
            // Renamed from "Discover" to "Search" for clarity
            NavigationView {
                SearchShowsView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            // Renamed from "Tracked" to "Library"
            TrackedListView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.cyan) // Modern accent color
    }
}