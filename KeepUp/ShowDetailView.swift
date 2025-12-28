import SwiftUI
import AVKit

struct ShowDetailView: View {
    @EnvironmentObject var appState: AppState
    let show: Show
    
    @State private var detailedShow: Show
    @State private var isLoadingDetails = false
    @State private var isLoadingAI = false
    @State private var errorMessage: String?
    @State private var providersVisible: Bool = false
    @State private var trackScale: CGFloat = 1.0
    @State private var reviewSummary: ReviewSummary = .empty
    @State private var isLoadingReviews = false
    @State private var isReviewSheetPresented = false
    
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
                                    .foregroundColor(.purple)
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
                            .background(appState.isTracked(detailedShow) ? Color.white.opacity(0.15) : Color.purple)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .scaleEffect(trackScale)
                        }
                        
                        // 3. AI INTELLIGENCE (Glass Section)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
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
                                                .foregroundColor(.purple)
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
                                        .foregroundColor(.purple)
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

                        // 7. REVIEWS (Glass Section)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.bubble")
                                    .foregroundColor(.purple)
                                Text("Reviews")
                                    .font(.headline)
                                    .foregroundColor(primaryTextColor)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("Current rating:")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    Text(detailedShow.rating ?? "Not available")
                                        .font(.subheadline)
                                        .foregroundColor(primaryTextColor)
                                }

                                if isLoadingReviews {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.purple)
                                        Text("Loading community rating...")
                                            .font(.subheadline)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                } else if reviewSummary.totalReviews > 0 {
                                    HStack(spacing: 8) {
                                        StarRatingView(rating: reviewSummary.averageRating, maxRating: 5)
                                        Text(String(format: "%.1f", reviewSummary.averageRating))
                                            .font(.subheadline)
                                            .foregroundColor(primaryTextColor)
                                        Text("(\(reviewSummary.totalReviews))")
                                            .font(.subheadline)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                } else {
                                    Text("No reviews yet.")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                }
                            }

                            Button {
                                isReviewSheetPresented = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("Write a review")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                        .padding()
                        .background(glassBackground)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.purple)
        }
        .task {
            await loadAllData()
            await loadReviewSummary()
        }
        .sheet(isPresented: $isReviewSheetPresented) {
            ReviewComposerSheet(
                show: detailedShow,
                reviewSummary: $reviewSummary
            )
            .environmentObject(appState)
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

    func loadReviewSummary() async {
        isLoadingReviews = true
        let summary = await appState.fetchReviewSummary(for: detailedShow.id)
        reviewSummary = summary
        isLoadingReviews = false
    }
}

// MARK: - Detail Row (Styled to match new theme)
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.6))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

private struct StarRatingView: View {
    let rating: Double
    let maxRating: Int

    private var roundedRating: Double {
        (rating * 2).rounded() / 2
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starName(for: index))
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }

    private func starName(for index: Int) -> String {
        if roundedRating >= Double(index) {
            return "star.fill"
        } else if roundedRating + 0.5 >= Double(index) {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

private struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    rating = index
                } label: {
                    Image(systemName: rating >= index ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(index) stars")
            }
        }
    }
}

private struct ReviewComposerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let show: Show
    @Binding var reviewSummary: ReviewSummary

    @State private var rating: Int = 0
    @State private var text: String = ""
    @State private var displayName: String = ""
    @State private var isSubmitting = false
    @State private var hasStoredDisplayName = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(show.title)
                            .font(.headline)
                        StarRatingPicker(rating: $rating)
                        Text("Tap a star to rate.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Your rating")
                }

                Section {
                    TextField("Display name", text: $displayName)
                        .textInputAutocapitalization(.words)
                    Text("Shown with your review. Stored to your account for future reviews.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Display name")
                } footer: {
                    if hasStoredDisplayName {
                        Text("You can update this once and it will apply across devices.")
                    }
                }

                Section("Review (optional)") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .overlay(
                            Text("Share what you liked or didn’t...")
                                .foregroundStyle(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .opacity(text.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Review")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(rating == 0 || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                if let name = await appState.fetchDisplayName() {
                    displayName = name
                    hasStoredDisplayName = true
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await appState.saveDisplayName(trimmedName)
            await appState.submitReview(
                for: show,
                rating: rating,
                text: trimmedText.isEmpty ? nil : trimmedText,
                displayName: trimmedName
            )
            let summary = await appState.fetchReviewSummary(for: show.id)
            reviewSummary = summary
            isSubmitting = false
            dismiss()
        }
    }
}

private extension ShowDetailView {
    var backgroundGradient: LinearGradient {
        return LinearGradient(
            colors: [Color(red: 0.04, green: 0.05, blue: 0.1), Color(red: 0.08, green: 0.1, blue: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var primaryTextColor: Color {
        .white
    }
    
    var secondaryTextColor: Color {
        Color.white.opacity(0.7)
    }
    
    var dividerColor: Color {
        Color.white.opacity(0.2)
    }
}
