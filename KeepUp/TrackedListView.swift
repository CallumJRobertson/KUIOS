import SwiftUI
import Foundation

// MARK: - Sorting Priority Enum
enum TrackedSortOrder: String, CaseIterable, Identifiable {
    case status = "Status Priority"
    case alpha = "Title A-Z"
    case year = "Year (Newest)"
    
    var id: String { rawValue }
}

// MARK: - Sorting Extension
extension Array where Element == Show {
    func sorted(by order: TrackedSortOrder) -> [Show] {
        switch order {
        case .alpha:
            return self.sorted { $0.title < $1.title }
        case .year:
            // Assuming Show.year is a String (e.g., "2024")
            return self.sorted { $0.year > $1.year }
        case .status:
            // Priority order: Renewed (1) > In Production (2) > Ending (3) > Unknown (4) > Concluded (5) > Cancelled (6)
            let priority: [String: Int] = [
                "renewed": 1,
                "in production": 2,
                "ending": 3,
                "unknown": 4,
                "concluded": 5,
                "cancelled": 6
            ]
            return self.sorted { (s1, s2) -> Bool in
                let p1 = priority[s1.aiStatus?.lowercased() ?? "unknown", default: 99]
                let p2 = priority[s2.aiStatus?.lowercased() ?? "unknown", default: 99]
                
                // Sort by priority first
                if p1 != p2 {
                    return p1 < p2
                }
                // Then by title as a tie-breaker
                return s1.title < s2.title
            }
        }
    }
}

struct TrackedListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSort: TrackedSortOrder = .status
    
    // Computed properties to access and sort the MainActor-isolated data
    var sortedSeries: [Show] {
        appState.trackedSeries.sorted(by: selectedSort)
    }
    
    var sortedMovies: [Show] {
        appState.trackedMovies.sorted(by: selectedSort)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // SECTION 1: TV SHOWS
                if !appState.trackedSeries.isEmpty {
                    Section("TV Shows") {
                        // Use sorted list
                        ForEach(sortedSeries) { show in
                            NavigationLink(destination: ShowDetailView(show: show)) {
                                TrackedRow(show: show)
                            }
                        }
                    }
                }
                
                // SECTION 2: MOVIES
                if !appState.trackedMovies.isEmpty {
                    Section("Movies") {
                        // Use sorted list
                        ForEach(sortedMovies) { show in
                            NavigationLink(destination: ShowDetailView(show: show)) {
                                TrackedRow(show: show)
                            }
                        }
                    }
                }
                
                // EMPTY STATE
                if appState.trackedShows.isEmpty {
                    ContentUnavailableView(
                        "No Shows Tracked",
                        systemImage: "tv.slash",
                        description: Text("Search for a show or movie and tap 'Track'.")
                    )
                }
            }
            .navigationTitle("Tracked")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Sort Menu
                    Menu {
                        Picker("Sort By", selection: $selectedSort) {
                            ForEach(TrackedSortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    
                    // Clear Tracked Button (existing)
                    if !appState.trackedShows.isEmpty {
                        Button(role: .destructive) {
                            appState.clearTracked()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // Keeping delete functions for safety, though they are not currently called by the UI.
    func deleteSeries(at offsets: IndexSet) {
        for index in offsets {
            let show = appState.trackedSeries[index]
            appState.toggleTracking(for: show)
        }
    }
    
    func deleteMovie(at offsets: IndexSet) {
        for index in offsets {
            let show = appState.trackedMovies[index]
            appState.toggleTracking(for: show)
        }
    }
}

private struct TrackedRow: View {
    let show: Show
    
    var body: some View {
        HStack(spacing: 12) {
            PosterThumbnail(url: show.posterURL)
            
            VStack(alignment: .leading, spacing: 6) {
                // Status badge from cached data
                if let status = show.aiStatus {
                    StatusBadge(status: status)
                }
                
                Text(show.title)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(show.year)
                    Text("•")
                    Text(show.type.displayName)
                    
                    if let rating = show.rating {
                        Text("•")
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(rating)
                        }
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Show arrow indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
