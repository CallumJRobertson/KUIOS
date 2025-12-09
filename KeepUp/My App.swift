// MyApp.swift
import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    // Changed: stored as a String to support 3 states ("system", "light", "dark")
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(selectedScheme)
        }
    }
    
    var selectedScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
}
