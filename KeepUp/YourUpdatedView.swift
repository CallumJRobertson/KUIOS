import SwiftUI

struct YourUpdateView: View {
    @EnvironmentObject var appState: AppState
    
    // Card Dimensions
    let cardWidth: CGFloat = 300
    let cardSpacing: CGFloat = 20
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 32) {
                            // MARK: - Recently Released (past N days)
                            if !appState.recentReleases.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recently Released")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 24)
                                    
                                    let sidePaddingRecent = max(0, (geo.size.width - cardWidth) / 2)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: cardSpacing) {
                                            ForEach(appState.recentReleases) { show in
                                                NavigationLink(destination: ShowDetailView(show: show)) {
                                                    SlideshowCard(show: show, width: cardWidth)
                                                }
                                                .buttonStyle(BouncyButtonStyle())
                                            }
                                        }
                                        .scrollTargetLayout()
                                    }
                                    .scrollTargetBehavior(.viewAligned)
                                    .contentMargins(.horizontal, sidePaddingRecent, for: .scrollContent)
                                }
                            }
                             
                             // MARK: - Centered Slideshow
                             if !appState.trackedUpdates.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Upcoming")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 24)
                                    
                                    // ✅ FIX: Use max(0, ...) to prevent negative numbers (NaN crash)
                                    let sidePadding = max(0, (geo.size.width - cardWidth) / 2)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: cardSpacing) {
                                            ForEach(appState.trackedUpdates) { show in
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
                            } else if appState.isLoadingUpdates {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                                    .padding(.top, 50)
                            } else {
                                VStack(spacing: 16) {
                                    ContentUnavailableView {
                                        Label("No scheduled airings", systemImage: "calendar.badge.exclamationmark")
                                    } description: {
                                        Text("Track a show to see upcoming episodes here.")
                                    }
                                    .foregroundStyle(.white.opacity(0.7))

                                    NavigationLink(destination: SearchShowsView()) {
                                        Label("Find shows to track", systemImage: "plus")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.cyan)
                                    .controlSize(.large)
                                    .padding(.horizontal, 40)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Updates")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
                await appState.loadUpdates()
                await appState.loadRecentReleases(windowDays: window == 0 ? 7 : window)
            }
        }
        .onAppear {
            Task {
                let window = UserDefaults.standard.integer(forKey: "recentWindowDays")
                await appState.loadUpdates()
                await appState.loadRecentReleases(windowDays: window == 0 ? 7 : window)
            }
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
            VStack(alignment: .leading, spacing: 6) {
                
                // Smart Date Badge
                if let date = show.nextAirDate {
                    Text(formatRelativeDate(date).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
                
                Text(show.title)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black, radius: 2)
                
                if let summary = show.aiSummary {
                    Text(cleanSummary(summary))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.cyan)
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
