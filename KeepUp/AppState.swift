import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Search state
    @Published var searchText: String = ""
    @Published var searchType: ShowType = .series
    @Published var searchResults: [Show] = []
    @Published var isSearching: Bool = false
    @Published var lastSearchError: String?
    
    // MARK: - Tracked state
    @Published var trackedShows: [Show] = []
    
    // MARK: - Dependencies
    private let client: TMDBClient
    private let trackedKey = "trackedShows"
    
    // MARK: - Init
    init(client: TMDBClient = TMDBClient(apiKey: Secrets.tmdbAPIKey)) {
        self.client = client
        loadTrackedFromDefaults()
    }
    
    // MARK: - Search
    func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            lastSearchError = nil
            return
        }
        
        if isSearching { return }
        isSearching = true
        lastSearchError = nil
        
        defer { isSearching = false }
        
        do {
            let results = try await client.search(query: query, type: searchType)
            self.searchResults = results
        } catch {
            self.lastSearchError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func clearSearchResults() {
        searchResults = []
        searchText = ""
        lastSearchError = nil
    }
    
    // MARK: - Tracked shows
    
    var trackedMovies: [Show] {
        trackedShows.filter { $0.type == .movie }
    }
    
    var trackedSeries: [Show] {
        trackedShows.filter { $0.type == .series }
    }
    
    func toggleTracking(for show: Show) {
        if let index = trackedShows.firstIndex(where: { $0.id == show.id }) {
            trackedShows.remove(at: index)
        } else {
            trackedShows.append(show)
        }
        saveTrackedToDefaults()
    }
    
    func isTracked(_ show: Show) -> Bool {
        trackedShows.contains { $0.id == show.id }
    }
    
    // NEW: Update a tracked show with new data (like AI status)
    func updateTrackedShow(_ updatedShow: Show) {
        if let index = trackedShows.firstIndex(where: { $0.id == updatedShow.id }) {
            trackedShows[index] = updatedShow
            saveTrackedToDefaults()
        }
    }
    
    // NEW: Get cached show data if available
    func getCachedShow(id: String) -> Show? {
        return trackedShows.first { $0.id == id }
    }
    
    func clearTracked() {
        trackedShows.removeAll()
        saveTrackedToDefaults()
    }
    
    // MARK: - Persistence
    private func saveTrackedToDefaults() {
        do {
            let data = try JSONEncoder().encode(trackedShows)
            UserDefaults.standard.set(data, forKey: trackedKey)
        } catch {
            print("Failed to save tracked shows: \(error)")
        }
    }
    
    private func loadTrackedFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: trackedKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([Show].self, from: data)
            self.trackedShows = decoded
        } catch {
            print("Failed to load tracked shows: \(error)")
        }
    }
}
