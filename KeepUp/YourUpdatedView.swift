import SwiftUI

struct YourUpdateView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("defaultHomeFeed") private var defaultHomeFeed: String = "recent"
    @State private var selectedFeed: HomeFeed = .recent
    
    // Card Dimensions
    let cardWidth: CGFloat = 300
    let cardSpacing: CGFloat = 20
    
    private enum HomeFeed: String, CaseIterable, Identifiable {
        case recent, upcoming
        var id: String { rawValue }
        var title: String {
            switch self {
            case .recent: return "Recently Released"
            case .upcoming: return "Upcoming"
            }
        }
    }
    
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.05, blue: 0.1), Color(red: 0.08, green: 0.1, blue: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            header
                                .padding(.top, 12)
                                .padding(.horizontal, 20)
                            
                            if isLoadingSelectedFeed {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.4)
                                    .padding(.top, 40)
                            } else if currentShows.isEmpty {
                                emptyState
                                    .frame(minHeight: geo.size.height * 0.5)
                                    .padding(.horizontal, 24)
                            } else {
                                feedSection(for: currentShows, in: geo.size)
                            }
                        }
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchShowsView()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
            }
            .refreshable { await reloadData() }
        }
        .onAppear {
            selectedFeed = HomeFeed(rawValue: defaultHomeFeed) ?? .recent
            Task { await reloadData() }
        }
        .onChange(of: selectedFeed) { _, _ in
            Task { await reloadSelectedFeedIfNeeded() }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stay on top of your shows")
                        .foregroundStyle(.white.opacity(0.78))
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
            }
            segmentedPill
        }
    }
    
    private var segmentedPill: some View {
        HStack(spacing: 8) {
            ForEach(HomeFeed.allCases) { feed in
                Button {
                    selectedFeed = feed
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(feed.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedFeed == feed ? .white : .white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedFeed == feed ? Color.purple.opacity(0.8) : Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(.white.opacity(selectedFeed == feed ? 0.2 : 0.08), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "feed-pill", in: animation, isSource: selectedFeed == feed)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func feedSection(for shows: [Show], in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedFeed.title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(1.4)
                .padding(.horizontal, 24)
            
            let sidePadding = max(0, (size.width - cardWidth) / 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(shows) { show in
                        NavigationLink(destination: ShowDetailView(show: show)) {
                            SlideshowCard(show: show, width: cardWidth)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, sidePadding, for: .scrollContent)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles.tv")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.purple)
                .padding(.bottom, 4)
            if appState.trackedShows.isEmpty {
                Text("No shows yet")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Track a show to see recently released and upcoming episodes here.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.subheadline)
                NavigationLink(destination: SearchShowsView()) {
                    Text("Track a show")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)
                .padding(.horizontal, 24)
            } else {
                Text("No updates yet")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("We couldn’t load updates right now. Pull to refresh or try again.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.subheadline)
                Button {
                    Task { await reloadData() }
                } label: {
                    Text("Try again")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)
                .padding(.horizontal, 24)
            }
        }
    }
    
    private var currentShows: [Show] {
        switch selectedFeed {
        case .recent: return appState.recentReleases
        case .upcoming: return appState.trackedUpdates
        }
    }
    
    private var isLoadingSelectedFeed: Bool {
        switch selectedFeed {
        case .recent: return appState.isLoadingRecentReleases
        case .upcoming: return appState.isLoadingUpdates
        }
    }
    
    private func reloadData() async {
        let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
        await appState.loadRecentReleases(windowDays: window == 0 ? 7 : window)
        await appState.loadUpdates()
    }

    private func reloadSelectedFeedIfNeeded() async {
        switch selectedFeed {
        case .recent:
            guard appState.recentReleases.isEmpty, !appState.isLoadingRecentReleases else { return }
            let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
            await appState.loadRecentReleases(windowDays: window == 0 ? 7 : window)
        case .upcoming:
            guard appState.trackedUpdates.isEmpty, !appState.isLoadingUpdates else { return }
            await appState.loadUpdates()
        }
    }
}

// MARK: - Fixed-Width Card with Relative Date
struct SlideshowCard: View {
    let show: Show
    let width: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Poster
            if let url = show.posterURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: width, height: width * 1.5)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.indigo.gradient)
                    .frame(width: width, height: width * 1.5)
            }
            
            // 2. Gradient
            LinearGradient(
                colors: [.black, .black.opacity(0.7), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 200)
            
            // 3. Text Info
            VStack(alignment: .leading, spacing: 8) {
                if let date = show.nextAirDate {
                    Label(formatRelativeDate(date).uppercased(), systemImage: "calendar")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.8), in: Capsule())
                }
                
                Text(show.title)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                
                if let summary = show.aiSummary {
                    Text(cleanSummary(summary))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.85))
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
                
                HStack {
                    Text(show.year)
                    Spacer()
                    if show.isNotificationEnabled == true {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(width: width, height: width * 1.5)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func cleanSummary(_ text: String) -> String {
        if let range = text.range(of: " on ") {
            return String(text[..<range.lowerBound])
        }
        return text
    }
    
    func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) { return "Tonight" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        
        if let days = calendar.dateComponents([.day], from: Date(), to: date).day, days < 6 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
