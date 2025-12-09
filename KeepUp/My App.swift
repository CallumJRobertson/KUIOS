// MyApp.swift
import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(useDarkMode ? .dark : nil) // nil = follow system
        }
    }
}
