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

            guard let data = document.data() else { return nil }

            // Try Data blob (some SDKs return Data)
            if let encodedData = data["tracked_shows_data"] as? Data {
                return try JSONDecoder().decode([Show].self, from: encodedData)
            }

            // Try NSData bridge (some SDK variants may return NSData)
            if let nsData = data["tracked_shows_data"] as? NSData {
                let bytes = Data(referencing: nsData)
                return try JSONDecoder().decode([Show].self, from: bytes)
            }

            // Try an array of bytes ([UInt8])
            if let byteArray = data["tracked_shows_data"] as? [UInt8] {
                let bytes = Data(byteArray)
                return try JSONDecoder().decode([Show].self, from: bytes)
            }

            // Try base64 string
            if let base64 = data["tracked_shows_base64"] as? String,
               let decoded = Data(base64Encoded: base64) {
                return try JSONDecoder().decode([Show].self, from: decoded)
            }

            // Sometimes it's stored directly as an array of dictionaries; attempt to convert
            if let array = data["tracked_shows_data"] as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
                return try JSONDecoder().decode([Show].self, from: jsonData)
            }

            // As a last resort, attempt to decode the entire document as JSON
            let json = try JSONSerialization.data(withJSONObject: data, options: [])
            if let decoded = try? JSONDecoder().decode([Show].self, from: json) {
                return decoded
            }

            return nil
        } catch {
            print("Failed to load tracked shows from Firestore: \(error)")
            return nil
        }
    }
}

// MARK: - AppState

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
    // MARK: - Recent Releases (within configurable window)
    @Published var recentReleases: [Show] = []
    @Published var isLoadingRecentReleases: Bool = false
    
    // MARK: - Dependencies
    private let client: TMDBClient
    private let firestoreClient = FirestoreClient()
    
    // MARK: - Init
    init(client: TMDBClient = TMDBClient(apiKey: Secrets.tmdbAPIKey)) {
        self.client = client
    }
    
    // MARK: - Bug Reporting with Diagnostics (NEW)
    func reportBug(title: String, description: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        // 1. Gather System Info
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        // 2. Create Rich Report Data
        let reportData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "Anonymous",
            "title": title,
            "description": description,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "open",
            
            // 🛠 DIAGNOSTICS BUNDLE
            "diagnostics": [
                "platform": "iOS",
                "os_version": "\(device.systemName) \(device.systemVersion)",
                "device_model": device.model,
                "app_version": appVersion,
                "build_number": buildNumber,
                "locale": Locale.current.identifier,
                "tracked_count": trackedShows.count
            ]
        ]
        
        do {
            try await Firestore.firestore().collection("bug_reports").addDocument(data: reportData)
            print("✅ Bug report submitted with diagnostics")
        } catch {
            print("❌ Failed to report bug: \(error)")
        }
    }
    
    // MARK: - Search Logic
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
        // Optional: clear searchText too if you want the field to reset
        // searchText = ""
        lastSearchError = nil
    }
    
    // MARK: - Cloud Persistence
    func loadTrackedShows(forUserID userID: String) {
        Task {
            if let shows = await firestoreClient.loadTrackedShows(forUserID: userID) {
                self.trackedShows = shows
                print("✅ Loaded \(shows.count) tracked shows from Firestore")
                await self.loadUpdates()
                let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
                await self.loadRecentReleases(windowDays: window == 0 ? 7 : window)
            } else {
                print("ℹ️ No tracked shows found for user \(userID)")
                // clear any stale lists
                await MainActor.run {
                    self.trackedUpdates = []
                    self.recentReleases = []
                }
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
        
        print("🔁 Loading upcoming updates for \(trackedShows.count) tracked shows")
        isLoadingUpdates = true
        defer { isLoadingUpdates = false }
        
        await withTaskGroup(of: Show?.self) { group in
            for show in trackedShows where show.type == .series {
                group.addTask {
                    do {
                        let detail = try await self.client.fetchNextSeasonDetails(for: show.id)
                        
                        // Include any show that has a next episode scheduled
                        if let nextEp = detail.nextEpisodeToAir {
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
            
            print("✅ Found \(newUpdates.count) upcoming shows")
            // Sort by next air date
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
    
    // MARK: - Recent Releases (episodes aired within the past `windowDays` days)
    func loadRecentReleases(windowDays: Int = 7) async {
        guard !trackedShows.isEmpty else {
            await MainActor.run { self.recentReleases = [] }
            return
        }

        print("🔁 Loading recent releases for \(trackedShows.count) tracked shows (windowDays=\(windowDays))")
        isLoadingRecentReleases = true
        defer { isLoadingRecentReleases = false }

        let calendar = Calendar.current
        let today = Date()

        await withTaskGroup(of: Show?.self) { group in
            for show in trackedShows where show.type == .series {
                group.addTask {
                    do {
                        let detail = try await self.client.fetchNextSeasonDetails(for: show.id)

                        // Prefer lastEpisodeToAir; fall back to nextEpisodeToAir if present
                        let ep = detail.lastEpisodeToAir ?? detail.nextEpisodeToAir
                        guard let episode = ep, let airDateStr = episode.airDate else { return nil }

                        // Parse air date
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        guard let airDate = formatter.date(from: airDateStr) else { return nil }

                        // daysAgo from airDate to today
                        if let daysAgo = calendar.dateComponents([.day], from: airDate, to: today).day,
                           daysAgo >= 0 && daysAgo <= windowDays {
                            var updated = show
                            updated.aiSummary = "Last Episode: S\(episode.seasonNumber ?? 0)E\(episode.episodeNumber ?? 0) on \(airDateStr)"
                            return updated
                        }
                    } catch {
                        print("Failed to fetch TV details for recent release check for \(show.title): \(error)")
                    }
                    return nil
                }
            }

            var found: [Show] = []
            for await item in group {
                if let s = item { found.append(s) }
            }

            print("✅ Found \(found.count) recent releases within \(windowDays) days")
            // Sort by most recent air date (descending)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let sorted = found.sorted { a, b in
                let aDate = formatter.date(from: a.aiSummary?.components(separatedBy: " on ").last ?? "")
                let bDate = formatter.date(from: b.aiSummary?.components(separatedBy: " on ").last ?? "")
                if let d1 = aDate, let d2 = bDate { return d1 > d2 }
                if aDate != nil { return true }
                if bDate != nil { return false }
                return a.title < b.title
            }

            await MainActor.run { self.recentReleases = sorted }
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
        saveTrackedToCloud()
        // Refresh updates & recent releases when tracking changes
        Task {
            await loadUpdates()
            let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
            await loadRecentReleases(windowDays: window == 0 ? 7 : window)
        }
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

    func scheduleLocalNotification(for show: Show) {
        guard let airDate = show.nextAirDate else {
            print("No next air date found for show \(show.title). Skipping notification scheduling.")
            return
        }

        // Schedule the notification for 9 AM on the air date
        let calendar = Calendar.current
        var triggerDateComponents = calendar.dateComponents([.year, .month, .day], from: airDate)
        triggerDateComponents.hour = 9
        triggerDateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "\(show.title) airs today"
        content.body = "Don't miss the new episode or release."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: show.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification for \(show.title): \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(show.title) on \(airDate)")
            }
        }
    }

    func cancelLocalNotification(for show: Show) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [show.id])
        print("Cancelled notification for \(show.title)")
    }
}
