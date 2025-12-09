import SwiftUI

struct SearchShowsView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var localSearchText = ""
    @State private var selectedType: ShowType = .series
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            // Search controls
            HStack {
                TextField("Search by title", text: $localSearchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { runSearch() }
                
                Menu {
                    Picker("Type", selection: $selectedType) {
                        Text("TV Shows").tag(ShowType.series)
                        Text("Movies").tag(ShowType.movie)
                    }
                } label: {
                    Text(selectedType.displayName)
                        .padding(.horizontal, 8)
                }
                .onChange(of: selectedType) { newValue in
                    appState.searchType = newValue
                }
                
                Button(action: runSearch) {
                    Image(systemName: "magnifyingglass")
                        .padding(.horizontal, 4)
                }
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
            
            // Loading State
            if appState.isSearching {
                ProgressView("Searching…")
                    .padding(.bottom)
            }
            
            // Error State
            if let error = appState.lastSearchError {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Results List
            List(appState.searchResults) { show in
                NavigationLink(destination: ShowDetailView(show: show)) {
                    SearchResultRow(
                        show: show,
                        isTracked: appState.isTracked(show),
                        cachedShow: appState.getCachedShow(id: show.id)
                    )
                }
            }
            .listStyle(.plain)
        }
        .onAppear {
            localSearchText = appState.searchText
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
    
    private func runSearch() {
        appState.searchText = localSearchText
        appState.searchType = selectedType
        isFocused = false
        
        Task {
            await appState.performSearch()
        }
    }
}

// MARK: - Row View
private struct SearchResultRow: View {
    let show: Show
    let isTracked: Bool
    let cachedShow: Show?
    
    var body: some View {
        HStack(spacing: 12) {
            PosterThumbnail(url: show.posterURL)
            
            VStack(alignment: .leading, spacing: 6) {
                // Status badge if cached
                if let status = cachedShow?.aiStatus {
                    StatusBadge(status: status)
                }
                
                Text(show.title)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(show.year)
                    Text("•")
                    Text(show.type.displayName)
                    
                    if let rating = cachedShow?.rating ?? show.rating {
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
            
            if isTracked {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared Thumbnail View
struct PosterThumbnail: View {
    let url: URL?
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 60, height: 90)
        .clipped()
        .cornerRadius(6)
        .shadow(radius: 2)
    }
    
    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Color.secondary.opacity(0.2))
            Image(systemName: "film")
                .imageScale(.large)
                .foregroundColor(.secondary)
        }
    }
}
