import SwiftUI

struct SearchShowsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var localSearchText = ""
    @State private var selectedType: ShowType = .series
    @FocusState private var isFocused: Bool
    @State private var isWaitingForResults = false

    var body: some View {
        ZStack {
            // Background adapts to light/dark
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Glass Search Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(secondaryTextColor)
                        
                        // ✅ SMOOTH: Auto-search field
                        TextField("Find movies & TV...", text: $localSearchText)
                            .foregroundColor(primaryTextColor)
                            .focused($isFocused)
                            .autocorrectionDisabled()
                        
                        if !localSearchText.isEmpty {
                            Button {
                                localSearchText = ""
                                appState.clearSearchResults() // Instant clear
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(secondaryTextColor)
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
                }
                .padding()
                .background(colorScheme == .light ? Color(.systemGray6) : Color(red: 0.05, green: 0.05, blue: 0.1))
                
                // MARK: - Results Area
                if isWaitingForResults || appState.isSearching {
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
                                .buttonStyle(BouncyButtonStyle())
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: appState.searchResults.count)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                    .scrollDismissesKeyboard(.immediately) // ✅ KEYBOARD: Dismiss on scroll
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(colorScheme == .light ? .light : .dark, for: .navigationBar)
         // ✅ DEBOUNCE: Trigger search automatically after 500ms of inactivity
        .task(id: localSearchText) {
            if localSearchText.count > 2 {
                // show waiting UI while debounce timer runs
                isWaitingForResults = true
                appState.lastSearchError = nil
                do {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                    appState.searchText = localSearchText
                    appState.searchType = selectedType
                    await appState.performSearch()
                } catch {
                    // cancellation during debounce - don't treat as error
                }
                isWaitingForResults = false
            } else if localSearchText.isEmpty {
                isWaitingForResults = false
                appState.clearSearchResults()
            }
        }
        .onChange(of: localSearchText) { newValue in
            if !newValue.isEmpty { appState.lastSearchError = nil }
        }
        // Also trigger if type changes
        .onChange(of: selectedType) { _ in
            appState.searchType = selectedType
            if !localSearchText.isEmpty {
                Task { await appState.performSearch() }
            }
        }
        // Auto-focus the search field so keyboard appears when the view opens
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                isFocused = true
            }
        }
     }
 }

// MARK: - Glass Result Card
struct SearchGlassCard: View {
    let show: Show
    let isTracked: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            PosterView(url: show.posterURL)
                .frame(width: 70, height: 105)
                .clipped()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(show.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .lineLimit(2)
                
                HStack {
                    Text(show.year)
                    Text("•")
                    Text(show.type.displayName)
                }
                .font(.caption)
                .foregroundColor(colorScheme == .light ? .secondary : Color.white.opacity(0.7))
                
                Spacer()
                
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
                .foregroundColor(colorScheme == .light ? .secondary : Color.white.opacity(0.3))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private extension SearchShowsView {
    var backgroundGradient: LinearGradient {
        if colorScheme == .light {
            return LinearGradient(
                colors: [Color(.systemGray6), Color(.white)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryTextColor: Color {
        colorScheme == .light ? .primary : .white
    }
    
    var secondaryTextColor: Color {
        colorScheme == .light ? .secondary : Color.white.opacity(0.6)
    }
}
