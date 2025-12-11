import SwiftUI

struct SearchShowsView: View {
    @EnvironmentObject var appState: AppState
    @State private var localSearchText = ""
    @State private var selectedType: ShowType = .series
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Global Deep Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Glass Search Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        
                        TextField("Find movies & TV...", text: $localSearchText)
                            .foregroundStyle(.white)
                            .focused($isFocused)
                            .submitLabel(.search)
                            .onSubmit { runSearch() }
                        
                        if !localSearchText.isEmpty {
                            Button {
                                localSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Type Switcher (TV/Movie)
                    Menu {
                        Picker("Type", selection: $selectedType) {
                            Text("TV Shows").tag(ShowType.series)
                            Text("Movies").tag(ShowType.movie)
                        }
                    } label: {
                        Image(systemName: selectedType == .series ? "tv" : "film")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundStyle(.cyan)
                    }
                    // ✅ FIXED: Updated to iOS 17 syntax (2 parameters)
                    .onChange(of: selectedType) { _, newValue in
                        appState.searchType = newValue
                        if !appState.searchText.isEmpty { runSearch() }
                    }
                }
                .padding()
                .background(Color(red: 0.05, green: 0.05, blue: 0.1)) // Header background
                
                // MARK: - Results Area
                if appState.isSearching {
                    Spacer()
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = appState.lastSearchError {
                    Spacer()
                    ContentUnavailableView {
                        Label("Search Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                } else if appState.searchResults.isEmpty && !appState.searchText.isEmpty {
                    Spacer()
                    ContentUnavailableView.search(text: appState.searchText)
                        .foregroundStyle(.white)
                    Spacer()
                } else {
                    // Result List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.searchResults) { show in
                                NavigationLink(destination: ShowDetailView(show: show)) {
                                    SearchGlassCard(show: show, isTracked: appState.isTracked(show))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarHidden(true)
        .onAppear {
            localSearchText = appState.searchText
        }
    }
    
    private func runSearch() {
        appState.searchText = localSearchText
        appState.searchType = selectedType
        isFocused = false
        Task { await appState.performSearch() }
    }
}

// MARK: - Glass Result Card
struct SearchGlassCard: View {
    let show: Show
    let isTracked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Poster
            PosterView(url: show.posterURL)
                .frame(width: 70, height: 105)
                .clipped()
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(show.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack {
                    Text(show.year)
                    Text("•")
                    Text(show.type.displayName)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                // Tracked Status
                if isTracked {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("IN LIBRARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.cyan)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}