import SwiftUI

struct TrackedListView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: ShowType? = nil // nil = All
    @State private var librarySearchText: String = "" // New: search within library
    
    // ✅ FIX: Adaptive columns (min 160px) to fill screen width
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var displayedShows: [Show] {
        let all = appState.trackedShows.sorted { $0.title < $1.title }
        // Apply type filter first
        let typeFiltered: [Show]
        if let filter = filter {
            typeFiltered = all.filter { $0.type == filter }
        } else {
            typeFiltered = all
        }
        // Then apply library search text if provided
        let query = librarySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return typeFiltered }
        return typeFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.aiSummary?.localizedCaseInsensitiveContains(query) ?? false) ||
            $0.year.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
         NavigationStack {
             ZStack {
                 // Global background aligned with Home (purple tone)
                 backgroundGradient
                     .ignoresSafeArea()
                
                 VStack(spacing: 0) {
                     // MARK: - Filter Chips
                     HStack(spacing: 12) {
                         FilterChip(title: "All", isSelected: filter == nil) { filter = nil }
                         FilterChip(title: "TV Shows", isSelected: filter == .series) { filter = .series }
                         FilterChip(title: "Movies", isSelected: filter == .movie) { filter = .movie }
                         Spacer()
                     }
                     .padding(.horizontal)
                     .padding(.top, 16)
                     .padding(.bottom, 16)
                     
                     // MARK: - Grid Content
                     if displayedShows.isEmpty {
                         VStack(spacing: 16) {
                             Image(systemName: "square.stack.3d.up.slash")
                                 .font(.system(size: 44, weight: .semibold))
                                 .foregroundColor(.purple)
                             Text("Library Empty")
                                 .font(.title3.bold())
                                 .foregroundColor(primaryTextColor)
                             Text("Track a show from Search to see it here.")
                                 .font(.subheadline)
                                 .foregroundColor(secondaryTextColor)
                             NavigationLink(destination: SearchShowsView()) {
                                 Text("Find shows")
                                     .font(.headline.weight(.semibold))
                                     .frame(maxWidth: .infinity)
                             }
                             .buttonStyle(.borderedProminent)
                             .tint(.purple)
                             .controlSize(.large)
                             .padding(.horizontal, 24)
                         }
                         .padding(.horizontal)
                         Spacer()
                     } else {
                         ScrollView {
                             LazyVGrid(columns: columns, spacing: 20) {
                                 ForEach(displayedShows) { show in
                                     NavigationLink(destination: ShowDetailView(show: show)) {
                                         LibraryGridCard(show: show)
                                     }
                                 }
                             }
                             .padding(.horizontal)
                             .padding(.bottom, 80)
                         }
                     }
                 }
             }
             .navigationTitle("Library")
             .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchShowsView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                }
             }
           .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
           .toolbarBackground(.visible, for: .navigationBar)
           .toolbarColorScheme(.dark, for: .navigationBar)
           .tint(.purple)
             // Enable native searchable UI in the navigation bar for library
             .searchable(text: $librarySearchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your library")
             // Improve keyboard dismissal behavior
             .onChange(of: librarySearchText) { _ in }
         }
    }
}

// MARK: - Grid Card
struct LibraryGridCard: View {
    let show: Show
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ✅ FIX: Use flexible poster to fill the grid cell
            ZStack(alignment: .topTrailing) {
                PosterView(url: show.posterURL, flexible: true)
                
                // Status Badge (if available)
                if let status = show.aiStatus {
                    Text(status.prefix(1).uppercased())
                        .font(.caption2)
                        .fontWeight(.black)
                        .padding(6)
                        .background(statusColor(status))
                        .clipShape(Circle())
                        .padding(6)
                }
            }
            
            // Minimal Info
            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .lineLimit(2) // ✅ FIX: Allow 2 lines for long titles
                    .multilineTextAlignment(.leading)
                    .frame(height: 50, alignment: .top) // ✅ FIX: Fixed height prevents jumping
                
                Text(show.year)
                    .font(.caption)
                    .foregroundColor(colorScheme == .light ? .secondary : Color.white.opacity(0.6))
            }
        }
    }
    
    func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "renewed", "returning": return .green
        case "cancelled", "ended": return .red
        default: return .gray
        }
    }
}

// MARK: - Filter Chip (Unchanged)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.purple.opacity(0.18))
                .foregroundColor(.white)
                 .clipShape(Capsule())
         }
      }
 }

 private extension TrackedListView {
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.05, blue: 0.1), Color(red: 0.08, green: 0.1, blue: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
     var secondaryTextColor: Color { Color.white.opacity(0.7) }
     var primaryTextColor: Color { .white }
 }
