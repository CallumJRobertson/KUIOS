import SwiftUI
import AVKit

struct ShowDetailView: View {
    @EnvironmentObject var appState: AppState
    let show: Show
    
    @State private var detailedShow: Show
    @State private var isLoadingDetails = false
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    
    init(show: Show) {
        self.show = show
        _detailedShow = State(initialValue: show)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // --- HERO HEADER ---
                ZStack(alignment: .topTrailing) {
                    // 1. Backdrop Image
                    if let url = detailedShow.backdropURL ?? detailedShow.posterURL {
                        // ✅ FIX: Corrected AsyncImage syntax
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: UIScreen.main.bounds.width * 0.6)
                                    .clipped()
                            case .failure:
                                Color.gray.opacity(0.4)
                                    .frame(height: UIScreen.main.bounds.width * 0.6)
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: UIScreen.main.bounds.width * 0.6)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                         Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: UIScreen.main.bounds.width * 0.6)
                    }
                    
                    // 2. Trailer Button and Notification Bell (Overlay)
                    HStack(spacing: 8) {
                        
                        // A. NOTIFICATION BELL BUTTON
                        Button {
                            toggleNotification() // ✅ Calls the helper function
                        } label: {
                            Image(systemName: (detailedShow.isNotificationEnabled ?? false) ? "bell.fill" : "bell")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        // B. TRAILER BUTTON
                        if let trailerKey = detailedShow.trailerKey,
                           let trailerURL = URL(string: "https://www.youtube.com/watch?v=\(trailerKey)") {
                            
                            Link(destination: trailerURL) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Trailer")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                        }
                    } // End HStack
                    .padding()
                }
                
                // --- MAIN CONTENT ---
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 1. TITLE & METADATA (Unchanged)
                    VStack(alignment: .leading, spacing: 8) {
                        if let status = detailedShow.aiStatus {
                            StatusBadge(status: status)
                        }
                        
                        Text(detailedShow.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 4) {
                            Text(detailedShow.year)
                            Text("•")
                            Text(detailedShow.type.displayName)
                            
                            if let rating = detailedShow.rating {
                                Text("•")
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text(rating)
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    // 2. TRACKING BUTTON (Unchanged)
                    Button {
                        appState.toggleTracking(for: detailedShow)
                    } label: {
                        HStack {
                            Image(systemName: appState.isTracked(detailedShow) ? "checkmark" : "plus")
                            Text(appState.isTracked(detailedShow) ? "Tracked" : "Track Show")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appState.isTracked(detailedShow) ? Color.secondary.opacity(0.2) : Color.accentColor)
                        .foregroundColor(appState.isTracked(detailedShow) ? .primary : .white)
                        .cornerRadius(12)
                    }
                    
                    // 3. AI INTELLIGENCE (Moved to the top)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Intelligence")
                                .font(.headline)
                            
                            if detailedShow.isCached == true {
                                Text("(Cached)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        if isLoadingAI {
                            HStack(spacing: 12) {
                                ProgressView()
                                VStack(alignment: .leading) {
                                    Text("Contacting Agent...")
                                        .font(.subheadline)
                                        .bold()
                                    Text("Analyzing show status")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                        } else if let error = errorMessage {
                            Text("Connection failed: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                        } else if let summary = detailedShow.aiSummary {
                            Text(summary)
                                .font(.body)
                                .padding(.bottom, 4)
                            
                            if let sources = detailedShow.aiSources, !sources.isEmpty {
                                Text("Sources:")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                                
                                ForEach(sources.indices, id: \.self) { index in
                                    if let urlString = sources[index].url, let url = URL(string: urlString) {
                                        Link(sources[index].title ?? "Source \(index+1)", destination: url)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        } else {
                            Text("No intelligence found.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)

                    // 4. WHERE TO WATCH (Unchanged)
                    if let providers = detailedShow.watchProviders, !providers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tv")
                                    .foregroundColor(.blue)
                                Text("Where to Watch")
                                    .font(.headline)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(providers) { provider in
                                        VStack(spacing: 4) {
                                            if let logoURL = provider.logoURL {
                                                AsyncImage(url: logoURL) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 50, height: 50)
                                                }
                                            }
                                            Text(provider.name)
                                                .font(.caption2)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 70)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    // 5. OVERVIEW (Unchanged)
                    if let plot = detailedShow.plot {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.headline)
                            Text(plot)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 6. DETAILS GRID (Unchanged)
                    if detailedShow.hasDetails {
                        VStack(spacing: 12) {
                            if let genre = detailedShow.genre {
                                DetailRow(label: "Genre", value: genre)
                            }
                            if let actors = detailedShow.actors {
                                DetailRow(label: "Cast", value: actors)
                            }
                            if let director = detailedShow.director {
                                DetailRow(label: detailedShow.type == .movie ? "Director" : "Creator", value: director)
                            }
                            if let runtime = detailedShow.runtime {
                                DetailRow(label: "Runtime", value: runtime)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Notification Logic Helper
    private func toggleNotification() {
        // 1. Toggle the local state
        var updatedShow = detailedShow
        let newState = !(updatedShow.isNotificationEnabled ?? false)
        updatedShow.isNotificationEnabled = newState
        detailedShow = updatedShow
        
        // 2. Schedule/Cancel Notification (Needs to be a Task for system calls)
        Task {
            if newState {
                appState.requestNotificationPermission()
                appState.scheduleLocalNotification(for: detailedShow)
            } else {
                appState.cancelLocalNotification(for: detailedShow)
            }
        }

        // 3. Update the persistent state (only if tracked)
        if appState.isTracked(detailedShow) {
            appState.updateTrackedShow(detailedShow)
        }
    }
    
    // MARK: - Data Loading
    
    func loadAllData() async {
        // Cache loading needs to handle the new isCached property too
        if let cached = appState.getCachedShow(id: show.id) {
            detailedShow = cached
        }
        if !detailedShow.hasDetails { await loadDetails() }
        if detailedShow.trailerKey == nil { await loadTrailer() }
        if detailedShow.watchProviders == nil { await loadWatchProviders() }
        if detailedShow.aiSummary == nil { await loadStatus() }
    }
    
    func loadDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let detailed = try await client.fetchDetails(for: show.id, type: show.type)
            // Preserve AI/Cache/Notification state when updating details
            var updated = detailed
            updated.aiStatus = detailedShow.aiStatus
            updated.aiSummary = detailedShow.aiSummary
            updated.aiSources = detailedShow.aiSources
            updated.isCached = detailedShow.isCached
            updated.isNotificationEnabled = detailedShow.isNotificationEnabled // Preserve notification state
            detailedShow = updated
        } catch { print("Failed to load details: \(error)") }
    }
    
    func loadTrailer() async {
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let trailerKey = try await client.fetchTrailer(for: show.id, type: show.type)
            detailedShow.trailerKey = trailerKey
        } catch { print("Failed to load trailer: \(error)") }
    }
    
    func loadWatchProviders() async {
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let providers = try await client.fetchWatchProviders(for: show.id, type: show.type)
            detailedShow.watchProviders = providers
        } catch { print("Failed to load watch providers: \(error)") }
    }
    
    // Correctly handles @State assignment and date context
    func loadStatus() async {
        guard detailedShow.aiSummary == nil else { return }
        isLoadingAI = true
        errorMessage = nil
        
        // Prepare date context for the backend
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        do {
            let isTV = (detailedShow.type == .series || detailedShow.type == .episode)
            
            // Call backend with date context
            let response = try await BackendClient.fetchStatus(for: detailedShow.title, isTV: isTV, currentDate: today)
            
            withAnimation {
                // Create mutable copy to update properties (Fixes Binding error)
                var updatedShow = detailedShow
                
                updatedShow.aiStatus = response.status
                updatedShow.aiSummary = response.summary
                updatedShow.aiSources = response.sources
                updatedShow.isCached = response.cached // Assign the new cache flag
                
                // Assign the entire updated struct back to @State
                detailedShow = updatedShow
                
                if appState.isTracked(detailedShow) {
                    appState.updateTrackedShow(detailedShow)
                }
            }
        } catch { self.errorMessage = error.localizedDescription }
        isLoadingAI = false
    }
}

// MARK: - Detail Row (Unchanged)

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }
}
