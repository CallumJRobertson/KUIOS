import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    init() {
        // Customize Tab Bar Appearance to match the dark theme
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.25)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.12)
        appearance.selectionIndicatorImage = UIImage.selectionDot(color: .systemPurple)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        appearance.stackedLayoutAppearance.selected.iconColor = .systemPurple
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemPurple]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().tintColor = .systemPurple

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        navAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.18)
        navAppearance.shadowColor = UIColor.white.withAlphaComponent(0.1)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemPurple
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            
            YourUpdateView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Removed the dedicated "Search" tab — search is now available from the Home toolbar.
            
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

private extension UIImage {
    static func selectionDot(color: UIColor) -> UIImage {
        let size = CGSize(width: 36, height: 26)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let dotSize: CGFloat = 6
            let dotRect = CGRect(
                x: (size.width - dotSize) / 2,
                y: size.height - dotSize - 4,
                width: dotSize,
                height: dotSize
            )
            context.cgContext.setFillColor(color.cgColor)
            context.cgContext.fillEllipse(in: dotRect)
        }.resizableImage(withCapInsets: .zero)
    }
}
