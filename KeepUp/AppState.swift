import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Search state
    @Published var searchText: String = ""
    @Published var searchType: ShowType = .series
    @Published var searchResults: [Show] = []
    @Published var isSearching: Bool = false
    @Published var lastSearchError: String?
    
    // MARK: - Navigation Control
    @Published var selectedTab: Int = 0 // ✅ NEW: Global tab selection state (default 0: My Update)
    
    // MARK: - Tracked state
    @Published var trackedShows: [Show] = []
    
    // MARK: - New Feature: Updates Tab
    @Published var trackedUpdates: [Show] = []
    @Published var isLoadingUpdates: Bool = false
    
    // MARK: - Dependencies
    private let client: TMDBClient
    private let trackedKey = "trackedShows"
    
    // MARK: - Init
    init(client: TMDBClient = TMDBClient(apiKey: Secrets.tmdbAPIKey)) {
        self.client = client
        loadTrackedFromDefaults()
    }
    
    // MARK: - Search (unchanged)
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
    
    // MARK: - Updates Tab Logic
    func loadUpdates() async {
        guard !trackedShows.isEmpty else { return }
        
        isLoadingUpdates = true
        
        defer { isLoadingUpdates = false }
        
        // Use a serial task group to check each series concurrently
        await withTaskGroup(of: Show?.self) { group in
            for show in trackedShows where show.type == .series {
                group.addTask {
                    do {
                        let detail = try await self.client.fetchNextSeasonDetails(for: show.id)
                        
                        if detail.status == "Returning Series", let nextEp = detail.nextEpisodeToAir {
                            var updatedShow = show
                            
                            let airDate = nextEp.airDate ?? "TBD"
                            updatedShow.aiSummary = "Next Episode: S\(nextEp.seasonNumber ?? 0)E\(nextEp.episodeNumber ?? 0) on \(airDate)"
                            return updatedShow
                        }
                        
                    } catch {
                        print("Failed to load details for \(show.title): \(error)")
                    }
                    return nil
                }
            }
            
            var newUpdates: [Show] = []
            for await updatedShow in group {
                if let show = updatedShow {
                    newUpdates.append(show)
                }
            }
            
            self.trackedUpdates = newUpdates.sorted { $0.title < $1.title }
        }
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
    
    // Update a tracked show with new data (including notification status)
    func updateTrackedShow(_ updatedShow: Show) {
        if let index = trackedShows.firstIndex(where: { $0.id == updatedShow.id }) {
            trackedShows[index] = updatedShow
            saveTrackedToDefaults()
        }
    }
    
    // Get cached show data if available
    func getCachedShow(id: String) -> Show? {
        return trackedShows.first { $0.id == id }
    }
    
    func clearTracked() {
        trackedShows.removeAll()
        saveTrackedToDefaults()
    }
    
    // MARK: - Push Notification Setup
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted. Registering for APNs.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
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
