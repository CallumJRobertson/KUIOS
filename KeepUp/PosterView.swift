import SwiftUI

struct PosterView: View {
    let url: URL?
    var large: Bool = false
    
    var body: some View {
        let size: CGFloat = large ? 140 : 70
        
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
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
        .frame(width: size, height: size * 1.5)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
    
    private var placeholder: some View {
        Image(systemName: "film")
            .resizable()
            .scaledToFit()
            .padding(16)
            .foregroundStyle(.secondary)
    }
}

