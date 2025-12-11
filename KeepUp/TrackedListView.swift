import SwiftUI

struct TrackedListView: View {
    @EnvironmentObject var appState: AppState
    @State private var filter: ShowType? = nil // nil = All
    
    // ✅ CHANGED: Increased spacing between columns for a bigger feel
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var displayedShows: [Show] {
        let all = appState.trackedShows.sorted { $0.title < $1.title }
        guard let filter = filter else { return all }
        return all.filter { $0.type == filter }
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
                
                VStack(spacing: 0) { // Removed initial vertical padding from VStack
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
                            // ✅ CHANGED: Increased vertical spacing
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(displayedShows) { show in
                                    NavigationLink(destination: ShowDetailView(show: show)) {
                                        LibraryGridCard(show: show)
                                    }
                                }
                            }
                            .padding(.horizontal) // Aligns with chips above
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Grid Card
struct LibraryGridCard: View {
    let show: Show
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster with Overlay
            ZStack(alignment: .topTrailing) {
                PosterView(url: show.posterURL)
                    .aspectRatio(2/3, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
                
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
            Text(show.title)
                // ✅ CHANGED: Larger font for bigger look
                .font(.headline) 
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Text(show.year)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
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