// YourUpdateView.swift
import SwiftUI

struct YourUpdateView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoadingUpdates {
                    ProgressView("Checking tracked shows for new episodes...")
                } else if appState.trackedShows.isEmpty {
                    // ✅ Actionable Empty State View
                    VStack {
                        ContentUnavailableView(
                            "Find Your Shows",
                            systemImage: "magnifyingglass.circle",
                            description: Text("Track your favorite TV shows and series to see their next air dates here.")
                        )
                        
                        Button("Start Tracking") {
                            // Action: Switch to Discover/Search Tab (Index 1)
                            appState.selectedTab = 1
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 10)
                    }
                    
                } else if appState.trackedUpdates.isEmpty {
                     ContentUnavailableView(
                        "No New Season Announcements",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("None of your tracked series have an announced return date yet.")
                    )
                } else {
                    List(appState.trackedUpdates) { show in
                        // ✅ FIX: The row is now clickable and navigates
                        NavigationLink(destination: ShowDetailView(show: show)) {
                            UpdateRow(show: show)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Update")
            .refreshable {
                // Allows user to manually reload the list
                await appState.loadUpdates()
            }
        }
        .onAppear {
            // Load updates only when the tab appears
            Task { await appState.loadUpdates() }
        }
    }
}

// MARK: - Row View tailored for Updates

private struct UpdateRow: View {
    let show: Show
    
    var body: some View {
        HStack(spacing: 12) {
            PosterView(url: show.posterURL) // Assuming PosterView is in scope
            
            VStack(alignment: .leading, spacing: 6) {
                Text(show.title)
                    .font(.headline)
                
                // Display the Update Summary extracted in AppState
                if let summary = show.aiSummary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor) // Fixed ShapeStyle error
                }
                
                HStack {
                    Text(show.year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if show.isNotificationEnabled == true {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.leading, 4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
