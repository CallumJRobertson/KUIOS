import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    // ✅ NEW: Access AuthManager to handle sign out
    @EnvironmentObject var authManager: AuthManager
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("includeMoviesInUpdates") private var includeMoviesInUpdates: Bool = false
    @AppStorage("autoClearSearch") private var autoClearSearch: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Global Deep Background
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - SECTION: ACCOUNT (NEW)
                        SettingsSection(title: "Account") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Signed in as")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text(authManager.userEmail ?? "User")
                                        .foregroundStyle(.white)
                                        .fontWeight(.medium)
                                }
                                Spacer()
                            }
                            
                            Divider().background(.white.opacity(0.2))
                            
                            Button(role: .destructive) {
                                authManager.signOut()
                            } label: {
                                HStack {
                                    Text("Sign Out")
                                    Spacer()
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                }
                                .foregroundStyle(.red)
                                .fontWeight(.semibold)
                            }
                        }
                        
                        // MARK: - SECTION: APPEARANCE
                        SettingsSection(title: "Appearance") {
                            HStack {
                                Text("Theme")
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $appTheme) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                        }
                        
                        // MARK: - SECTION: LIBRARY & TRACKING
                        SettingsSection(title: "Library & Tracking") {
                            ToggleRow(title: "Include Movies in Updates", isOn: $includeMoviesInUpdates)
                            
                            Divider().background(.white.opacity(0.2))
                            
                            ToggleRow(title: "Haptic Feedback", isOn: $hapticsEnabled)
                            
                            Divider().background(.white.opacity(0.2))
                            
                            Button(role: .destructive) {
                                appState.clearTracked()
                            } label: {
                                HStack {
                                    Text("Clear Library")
                                    Spacer()
                                    Image(systemName: "trash")
                                }
                                .foregroundStyle(.red)
                            }
                        }
                        
                        // MARK: - SECTION: SEARCH EXPERIENCE
                        SettingsSection(title: "Search Experience") {
                            ToggleRow(title: "Auto-clear Search Field", isOn: $autoClearSearch)
                            
                            Divider().background(.white.opacity(0.2))
                            
                            Button(role: .destructive) {
                                appState.clearSearchResults()
                            } label: {
                                HStack {
                                    Text("Clear Search History")
                                    Spacer()
                                    Image(systemName: "xmark.circle")
                                }
                                .foregroundStyle(.red)
                            }
                        }
                        
                        // MARK: - SECTION: ABOUT
                        SettingsSection(title: "About") {
                            InfoRow(label: "Version", value: "1.0.0 Beta")
                            Divider().background(.white.opacity(0.2))
                            InfoRow(label: "Developer", value: "Callum")
                        }
                        
                        Text("KeepUp Tracker")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// ... (Keep the Reusable Components like SettingsSection, ToggleRow, InfoRow at the bottom unchanged)
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.leading, 8)
            
            VStack(spacing: 16) {
                content
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).foregroundStyle(.white)
        }
        .tint(.cyan)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.white)
            Spacer()
            Text(value).foregroundStyle(.white.opacity(0.6))
        }
    }
}
