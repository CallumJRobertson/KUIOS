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
                                    .id(selectedFeed)
                                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                            removal: .opacity))
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
                            .background(.ultraThinMaterial, in: Capsule())
                            .offset(y: 2)
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedFeed)
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
        .padding(16)
        .background {
            AnimatedHeaderBackground()
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var segmentedPill: some View {
        HStack(spacing: 8) {
            ForEach(HomeFeed.allCases) { feed in
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        selectedFeed = feed
                    }
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
                                .shadow(color: selectedFeed == feed ? Color.purple.opacity(0.45) : Color.black.opacity(0.2),
                                        radius: selectedFeed == feed ? 12 : 6, y: 4)
                                .matchedGeometryEffect(id: "feed-pill", in: animation, isSource: selectedFeed == feed)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
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
                .foregroundStyle(.cyan)
                .padding(.bottom, 4)
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
            .tint(.blue)
            .controlSize(.large)
            .padding(.horizontal, 24)
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
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let parallax = minX * -0.12
            
            ZStack(alignment: .bottom) {
                // 1. Poster
                if let url = show.posterURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: width, height: width * 1.5)
                    .offset(x: parallax)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.indigo.gradient)
                        .frame(width: width, height: width * 1.5)
                }
                
                // 2. Gradient
                LinearGradient(
                    colors: [.black, .black.opacity(0.75), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(height: 220)
                
                // 3. Text Info
                VStack(alignment: .leading, spacing: 10) {
                    if let date = show.nextAirDate {
                        Label(formatRelativeDate(date).uppercased(), systemImage: "calendar")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.18), in: Capsule())
                    }
                    
                    Text(show.title)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .tracking(-0.4)
                        .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                    
                    if let summary = show.aiSummary {
                        Text(cleanSummary(summary))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
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
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(20)
            }
            .frame(width: width, height: width * 1.5)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: accentColor.opacity(0.45), radius: 24, x: 0, y: 12)
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .frame(width: width, height: width * 1.5)
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
    
    private var accentColor: Color {
        let palette: [Color] = [
            Color.red, Color.pink, Color.purple, Color.blue, Color.teal, Color.orange
        ]
        let index = abs(show.title.hashValue) % palette.count
        return palette[index]
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct AnimatedHeaderBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.6)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let shift = 0.12 * sin(time / 6)
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.purple.opacity(0.18),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: UnitPoint(x: 0.1 + shift, y: 0),
                    endPoint: UnitPoint(x: 0.9 - shift, y: 1)
                )
                .blendMode(.screen)
                
                NoiseOverlay()
                    .opacity(0.25)
            }
            .background(.ultraThinMaterial)
        }
    }
}

private struct NoiseOverlay: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<120 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(Path(rect), with: .color(.white.opacity(0.12)))
            }
        }
        .blendMode(.overlay)
    }
}
