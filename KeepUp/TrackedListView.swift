import SwiftUI

struct TrackedListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                // SECTION 1: TV SHOWS
                if !appState.trackedSeries.isEmpty {
                    Section("TV Shows") {
                        ForEach(appState.trackedSeries) { show in
                            NavigationLink(destination: ShowDetailView(show: show)) {
                                TrackedRow(show: show)
                            }
                        }
                        .onDelete(perform: deleteSeries)
                    }
                }
                
                // SECTION 2: MOVIES
                if !appState.trackedMovies.isEmpty {
                    Section("Movies") {
                        ForEach(appState.trackedMovies) { show in
                            NavigationLink(destination: ShowDetailView(show: show)) {
                                TrackedRow(show: show)
                            }
                        }
                        .onDelete(perform: deleteMovie)
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
                if !appState.trackedShows.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
