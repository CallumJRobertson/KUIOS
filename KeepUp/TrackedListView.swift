import SwiftUI

struct TrackedListView: View {
    @EnvironmentObject var appState: AppState
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
                // Global Deep Background
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // MARK: - Grid Content
                    if displayedShows.isEmpty {
                        ContentUnavailableView(
                            "Library Empty",
                            systemImage: "square.stack.3d.up.slash",
                            description: Text("Add shows from Search to build your collection.")
                        )
                        .foregroundStyle(.white.opacity(0.7))
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                    .foregroundStyle(.white)
                    .lineLimit(2) // ✅ FIX: Allow 2 lines for long titles
                    .multilineTextAlignment(.leading)
                    .frame(height: 50, alignment: .top) // ✅ FIX: Fixed height prevents jumping
                
                Text(show.year)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
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
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.1))
                .foregroundStyle(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
    }
}
