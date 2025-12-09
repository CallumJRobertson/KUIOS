// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark mode", isOn: $useDarkMode)
                }
                
                Section("Tracking") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Button(role: .destructive) {
                        appState.clearTracked()
                    } label: {
                        Text("Clear tracked list")
                    }
                }
                
                Section("Search") {
                    Button("Clear last search") {
                        appState.clearSearchResults()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Callum")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
