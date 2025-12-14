import SwiftUI

struct PosterView: View {
    let url: URL?
    var large: Bool = false
    // ✅ NEW: Add a flexible mode for Grids
    var flexible: Bool = false
    @State private var imageLoaded: Bool = false
    
    var body: some View {
        // If flexible, use infinity (fill space). If not, use fixed sizes.
        let width: CGFloat? = flexible ? nil : (large ? 140 : 70)
        let height: CGFloat? = flexible ? nil : (large ? 210 : 105)
        
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(imageLoaded ? 1 : 0)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.35)) {
                                    imageLoaded = true
                                }
                            }
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        // ✅ FIX: Use frame constraints based on mode
        .frame(width: width, height: height)
        .aspectRatio(2/3, contentMode: .fit) // Enforce poster shape
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
    
    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "film")
                .resizable()
                .scaledToFit()
                .padding(20)
                .foregroundStyle(.secondary)
        }
    }
}
