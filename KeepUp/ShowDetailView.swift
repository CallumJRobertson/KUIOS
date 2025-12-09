import SwiftUI
import AVKit

struct ShowDetailView: View {
    @EnvironmentObject var appState: AppState
    let show: Show
    
    @State private var detailedShow: Show
    @State private var isLoadingDetails = false
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var showTrailer = false
    
    init(show: Show) {
        self.show = show
        _detailedShow = State(initialValue: show)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // --- HERO HEADER WITH TRAILER BUTTON ---
                ZStack(alignment: .bottomLeading) {
                    // Backdrop image
                    if let url = detailedShow.backdropURL ?? detailedShow.posterURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 350)
                                .clipped()
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 350)
                        }
                    }
                    
                    // Dark Gradient
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.9)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 350)
                    
                    // Trailer button (top right)
                    if let trailerKey = detailedShow.trailerKey {
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    showTrailer = true
                                } label: {
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
                                .padding()
                            }
                            Spacer()
                        }
                        .frame(height: 350)
                        .sheet(isPresented: $showTrailer) {
                            TrailerPlayerView(youtubeKey: trailerKey)
                        }
                    }
                    
                    // Title & Badge
                    VStack(alignment: .leading, spacing: 8) {
                        if let status = detailedShow.aiStatus {
                            StatusBadge(status: status)
                        }
                        
                        Text(detailedShow.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        HStack(spacing: 4) {
                            Text(detailedShow.year)
                            Text("•")
                            Text(detailedShow.type.displayName)
                            
                            if let rating = detailedShow.rating {
                                Text("•")
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                    Text(rating)
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                VStack(spacing: 20) {
                    // --- TRACKING BUTTON ---
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
                    
                    // --- WHERE TO WATCH ---
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
                    
                    // --- OVERVIEW ---
                    if let plot = detailedShow.plot {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.headline)
                            Text(plot)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // --- DETAILS GRID ---
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
                    
                    // --- AI INTELLIGENCE ---
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Intelligence")
                                .font(.headline)
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
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await loadAllData()
        }
    }
    
    func loadAllData() async {
        // Check if we have cached data first
        if let cached = appState.getCachedShow(id: show.id) {
            detailedShow = cached
        }
        
        // Load details if needed
        if !detailedShow.hasDetails {
            await loadDetails()
        }
        
        // Load trailer if needed
        if detailedShow.trailerKey == nil {
            await loadTrailer()
        }
        
        // Load watch providers if needed
        if detailedShow.watchProviders == nil {
            await loadWatchProviders()
        }
        
        // Load AI status if needed
        if detailedShow.aiSummary == nil {
            await loadStatus()
        }
    }
    
    func loadDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }
        
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let detailed = try await client.fetchDetails(for: show.id, type: show.type)
            
            // Preserve any existing AI data
            var updated = detailed
            updated.aiStatus = detailedShow.aiStatus
            updated.aiSummary = detailedShow.aiSummary
            updated.aiSources = detailedShow.aiSources
            
            detailedShow = updated
        } catch {
            print("Failed to load details: \(error)")
        }
    }
    
    func loadTrailer() async {
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let trailerKey = try await client.fetchTrailer(for: show.id, type: show.type)
            detailedShow.trailerKey = trailerKey
        } catch {
            print("Failed to load trailer: \(error)")
        }
    }
    
    func loadWatchProviders() async {
        do {
            let client = TMDBClient(apiKey: Secrets.tmdbAPIKey)
            let providers = try await client.fetchWatchProviders(for: show.id, type: show.type)
            detailedShow.watchProviders = providers
        } catch {
            print("Failed to load watch providers: \(error)")
        }
    }
    
    func loadStatus() async {
        guard detailedShow.aiSummary == nil else { return }
        isLoadingAI = true
        errorMessage = nil
        
        do {
            let isTV = (detailedShow.type == .series || detailedShow.type == .episode)
            let response = try await BackendClient.fetchStatus(for: detailedShow.title, isTV: isTV)
            
            withAnimation {
                detailedShow.aiStatus = response.status
                detailedShow.aiSummary = response.summary
                detailedShow.aiSources = response.sources
                
                // Update cached version if tracked
                if appState.isTracked(detailedShow) {
                    appState.updateTrackedShow(detailedShow)
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingAI = false
    }
}

// MARK: - Detail Row

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

// MARK: - Trailer Player

struct TrailerPlayerView: View {
    let youtubeKey: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let url = URL(string: "https://www.youtube.com/embed/\(youtubeKey)") {
                    WebView(url: url)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - WebView for YouTube

import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
