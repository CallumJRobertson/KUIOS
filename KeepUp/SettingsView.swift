// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    // Changed: matches the key in MyApp
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
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
                        Text("0.1.1")
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
