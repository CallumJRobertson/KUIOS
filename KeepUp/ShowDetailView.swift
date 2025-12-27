import SwiftUI
import AVKit

struct ShowDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let show: Show
    
    @State private var detailedShow: Show
    @State private var isLoadingDetails = false
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var providersVisible: Bool = false
    @State private var trackScale: CGFloat = 1.0
    
    init(show: Show) {
        self.show = show
        _detailedShow = State(initialValue: show)
    }

    private var tmdbClient: TMDBClient { appState.tmdbClient }

    // Custom Glass Material Background
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .stroke(Color.white.opacity(0.1), lineWidth: 1)
    }
    
    var body: some View {
        ZStack {
            // MARK: - 0. Global Background (adapts to light/dark)
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // --- HERO HEADER ---
                    ZStack(alignment: .topTrailing) {
                        // 1. Backdrop Image
                        if let url = detailedShow.backdropURL ?? detailedShow.posterURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: UIScreen.main.bounds.width * 0.6)
                                        .clipped()
                                case .failure, .empty:
                                    Rectangle()
                                        .fill(Color(red: 0.2, green: 0.2, blue: 0.4).gradient)
                                        .frame(height: UIScreen.main.bounds.width * 0.6)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                             Rectangle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.4).gradient)
                                .frame(height: UIScreen.main.bounds.width * 0.6)
                        }
                        
                        // 2. Gradient Overlay to darken the bottom edge
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: UIScreen.main.bounds.width * 0.6)
                        
                        // 3. Trailer Button and Notification Bell (Overlay)
                        HStack(spacing: 8) {
                            
                            // A. NOTIFICATION BELL BUTTON
                            Button {
                                toggleNotification()
                            } label: {
                                Image(systemName: (detailedShow.isNotificationEnabled ?? false) ? "bell.fill" : "bell")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.yellow)
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
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // --- MAIN CONTENT ---
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 1. TITLE & METADATA
                        VStack(alignment: .leading, spacing: 8) {
                            if let status = detailedShow.aiStatus {
                                StatusBadge(status: status)
                            }
                            
                            Text(detailedShow.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(primaryTextColor)
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
                            .foregroundColor(secondaryTextColor)
                        }
                        
                        // 2. TRACKING BUTTON (haptic + subtle pop)
                        Button {
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                trackScale = 0.94
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                appState.toggleTracking(for: detailedShow)
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                                    trackScale = 1.0
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: appState.isTracked(detailedShow) ? "checkmark" : "plus")
                                Text(appState.isTracked(detailedShow) ? "In Library" : "Track Show")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appState.isTracked(detailedShow) ? Color.white.opacity(0.15) : Color.cyan)
                            .foregroundColor(appState.isTracked(detailedShow) ? .white : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .scaleEffect(trackScale)
                        }
                        
                        // 3. AI INTELLIGENCE (Glass Section)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.cyan)
                                Text("AI Status")
                                    .font(.headline)
                                    .foregroundColor(primaryTextColor)
                                
                                if detailedShow.isCached == true {
                                    Text("(Cached)")
                                        .font(.caption)
                                        .foregroundColor(secondaryTextColor)
                                }
                            }
                            
                            if isLoadingAI {
                                HStack(spacing: 12) {
                                    ProgressView().tint(.purple)
                                    Text("Analyzing show status...")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                }
                            } else if let error = errorMessage {
                                Text("Connection failed: \(error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if let summary = detailedShow.aiSummary {
                                Text(summary)
                                    .font(.body)
                                    .foregroundColor(primaryTextColor)
                                
                                if let sources = detailedShow.aiSources, !sources.isEmpty {
                                    Divider().background(dividerColor)
                                    Text("Sources:")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(secondaryTextColor)
                                    
                                    ForEach(sources.indices, id: \.self) { index in
                                        if let urlString = sources[index].url, let url = URL(string: urlString) {
                                            Link(sources[index].title ?? "Source \(index+1)", destination: url)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(glassBackground)

                        // 4. OVERVIEW
                        if let plot = detailedShow.plot {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Overview")
                                    .font(.headline)
                                    .foregroundColor(primaryTextColor)
                                Text(plot)
                                    .font(.body)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }

                        // 5. WHERE TO WATCH (Glass Section)
                        if let providers = detailedShow.watchProviders, !providers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "tv")
                                        .foregroundColor(.cyan)
                                    Text("Where to Watch")
                                        .font(.headline)
                                        .foregroundColor(primaryTextColor)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(providers) { provider in
                                            VStack(spacing: 4) {
                                                if let logoURL = provider.logoURL {
                                                    AsyncImage(url: logoURL) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 70, height: 70)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                            .shadow(radius: 2)
                                                    } placeholder: {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.white.opacity(0.08))
                                                            .frame(width: 70, height: 70)
                                                            .overlay(
                                                                ProgressView()
                                                                    .tint(.white.opacity(0.7))
                                                            )
                                                    }
                                                }
                                                Text(provider.name)
                                                    .font(.caption2)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 80)
                                                    .foregroundColor(secondaryTextColor)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(glassBackground)
                        }
                        
                        // 6. DETAILS GRID (Glass Section)
                        if detailedShow.hasDetails {
                            VStack(spacing: 16) {
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
                            .background(glassBackground)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .light ? .light : .dark, for: .navigationBar)
        }
        .task {
            await loadAllData()
        }
    }
    
    // MARK: - Notification Logic Helper (Unchanged)
    private func toggleNotification() {
        var updatedShow = detailedShow
        let newState = !(updatedShow.isNotificationEnabled ?? false)
        updatedShow.isNotificationEnabled = newState
        detailedShow = updatedShow
        
        Task {
            if newState {
                appState.requestNotificationPermission()
                appState.scheduleLocalNotification(for: detailedShow)
            } else {
                appState.cancelLocalNotification(for: detailedShow)
            }
        }

        if appState.isTracked(detailedShow) {
            appState.updateTrackedShow(detailedShow)
        }
    }
    
    // MARK: - Data Loading (Unchanged)
    func loadAllData() async {
        if let cached = appState.getCachedShow(id: show.id) {
            detailedShow = cached
        }

        let sharedClient = tmdbClient
        await withTaskGroup(of: Void.self) { group in
            if !detailedShow.hasDetails {
                group.addTask { await loadDetails(using: sharedClient) }
            }

            if detailedShow.trailerKey == nil {
                group.addTask { await loadTrailer(using: sharedClient) }
            }

            if detailedShow.watchProviders == nil {
                group.addTask { await loadWatchProviders(using: sharedClient) }
            }

            if detailedShow.aiSummary == nil {
                group.addTask { await loadStatus() }
            }
        }
    }

    func loadDetails(using client: TMDBClient) async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }
        do {
            let detailed = try await client.fetchDetails(for: show.id, type: show.type)
            var updated = detailed
            updated.aiStatus = detailedShow.aiStatus
            updated.aiSummary = detailedShow.aiSummary
            updated.aiSources = detailedShow.aiSources
            updated.isCached = detailedShow.isCached
            updated.isNotificationEnabled = detailedShow.isNotificationEnabled
            detailedShow = updated
        } catch { print("Failed to load details: \(error)") }
    }
    
    func loadTrailer(using client: TMDBClient) async {
        do {
            let trailerKey = try await client.fetchTrailer(for: show.id, type: show.type)
            detailedShow.trailerKey = trailerKey
        } catch { print("Failed to load trailer: \(error)") }
    }

    func loadWatchProviders(using client: TMDBClient) async {
        do {
            let providers = try await client.fetchWatchProviders(for: show.id, type: show.type)
            detailedShow.watchProviders = providers
        } catch { print("Failed to load watch providers: \(error)") }
    }
    
    func loadStatus() async {
        guard detailedShow.aiSummary == nil else { return }
        isLoadingAI = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        do {
            let isTV = (detailedShow.type == .series || detailedShow.type == .episode)
            
            let response = try await BackendClient.fetchStatus(for: detailedShow.title, isTV: isTV, currentDate: today)
            
            withAnimation {
                var updatedShow = detailedShow
                
                updatedShow.aiStatus = response.status
                updatedShow.aiSummary = response.summary
                updatedShow.aiSources = response.sources
                updatedShow.isCached = response.cached
                
                detailedShow = updatedShow
                
                if appState.isTracked(detailedShow) {
                    appState.updateTrackedShow(detailedShow)
                }
            }
        } catch { self.errorMessage = error.localizedDescription }
        isLoadingAI = false
    }
}

// MARK: - Detail Row (Styled to match new theme)
private struct DetailRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(colorScheme == .light ? .primary : .white.opacity(0.6))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(colorScheme == .light ? .primary : .white)
            Spacer()
        }
    }
}

private extension ShowDetailView {
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
        colorScheme == .light ? .secondary : Color.white.opacity(0.7)
    }
    
    var dividerColor: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.2)
    }
}
