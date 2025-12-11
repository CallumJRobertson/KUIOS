import Foundation
import SwiftUI
import UserNotifications
import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Client (Handles encoding/decoding for cloud storage)
private struct FirestoreClient {
    // ✅ Lazily access Firestore so FirebaseApp.configure() has already run
    private var db: Firestore { Firestore.firestore() }
    
    func saveTrackedShows(_ shows: [Show], forUserID userID: String) {
        do {
            let encodedData = try JSONEncoder().encode(shows)
            
            db.collection("users").document(userID).setData([
                "tracked_shows_data": encodedData
            ]) { error in
                if let error = error {
                    print("Error writing document: \(error)")
                }
            }
        } catch {
            print("Failed to encode shows for Firestore: \(error)")
        }
    }
    
    func loadTrackedShows(forUserID userID: String) async -> [Show]? {
        do {
            let document = try await db.collection("users").document(userID).getDocument()
            
            guard let data = document.data(),
                  let encodedData = data["tracked_shows_data"] as? Data else {
                return nil
            }
            
            return try JSONDecoder().decode([Show].self, from: encodedData)
        } catch {
            print("Failed to load tracked shows from Firestore: \(error)")
            return nil
        }
    }
}

// MARK: - AppState (Refactored for Cloud Persistence)

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Search state
    @Published var searchText: String = ""
    @Published var searchType: ShowType = .series
    @Published var searchResults: [Show] = []
    @Published var isSearching: Bool = false
    @Published var lastSearchError: String?
    
    // MARK: - Navigation Control
    @Published var selectedTab: Int = 0
    
    // MARK: - Tracked state
    @Published var trackedShows: [Show] = []
    
    // MARK: - Updates Tab
    @Published var trackedUpdates: [Show] = []
    @Published var isLoadingUpdates: Bool = false
    
    // MARK: - Dependencies
    private let client: TMDBClient
    private let firestoreClient = FirestoreClient()
    
    // MARK: - Init
    init(client: TMDBClient = TMDBClient(apiKey: Secrets.tmdbAPIKey)) {
        self.client = client
    }
    
    // MARK: - Cloud Persistence
    
    func loadTrackedShows(forUserID userID: String) {
        Task {
            if let shows = await firestoreClient.loadTrackedShows(forUserID: userID) {
                self.trackedShows = shows
                await self.loadUpdates()
            }
        }
    }
    
    private func saveTrackedToCloud() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No logged-in user to save data to.")
            return
        }
        firestoreClient.saveTrackedShows(trackedShows, forUserID: userID)
    }
    
    func clearAllData() {
        trackedShows.removeAll()
        trackedUpdates.removeAll()
        clearSearchResults()
    }
    
    // MARK: - Updates Tab Logic
    func loadUpdates() async {
        guard !trackedShows.isEmpty else { return }
        
        isLoadingUpdates = true
        defer { isLoadingUpdates = false }
        
        await withTaskGroup(of: Show?.self) { group in
            for show in trackedShows where show.type == .series {
                group.addTask {
                    do {
                        let detail = try await self.client.fetchNextSeasonDetails(for: show.id)
                        
                        if detail.status == "Returning Series",
                           let nextEp = detail.nextEpisodeToAir {
                            var updatedShow = show
                            
                            let airDate = nextEp.airDate ?? "TBD"
                            updatedShow.aiSummary =
                                "Next Episode: S\(nextEp.seasonNumber ?? 0)E\(nextEp.episodeNumber ?? 0) on \(airDate)"
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
            
            self.trackedUpdates = newUpdates.sorted {
                if let d1 = $0.nextAirDate, let d2 = $1.nextAirDate {
                    return d1 < d2
                }
                if $0.nextAirDate != nil { return true }
                if $1.nextAirDate != nil { return false }
                
                return $0.title < $1.title
            }
        }
    }
    
    // MARK: - Tracked shows (with cloud saving)
    
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
        saveTrackedToCloud()
    }
    
    func isTracked(_ show: Show) -> Bool {
        trackedShows.contains { $0.id == show.id }
    }
    
    func updateTrackedShow(_ updatedShow: Show) {
        if let index = trackedShows.firstIndex(where: { $0.id == updatedShow.id }) {
            trackedShows[index] = updatedShow
            saveTrackedToCloud()
        }
    }
    
    func getCachedShow(id: String) -> Show? {
        trackedShows.first { $0.id == id }
    }
    
    func clearTracked() {
        trackedShows.removeAll()
        saveTrackedToCloud()
    }
    
    // MARK: - Other methods (currently stubs – you can re-paste your original implementations)
    func performSearch() async { /* ... */ }
    func clearSearchResults() { /* ... */ }
    func requestNotificationPermission() { /* ... */ }
    func scheduleLocalNotification(for show: Show) { /* ... */ }
    func cancelLocalNotification(for show: Show) { /* ... */ }
}
