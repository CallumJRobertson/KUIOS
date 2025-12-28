import SwiftUI

struct TMDBLogoView: View {
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.purple)
                .frame(width: 18, height: 18)
                .overlay(
                    Text("TM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                )
            Text("TMDB")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TMDBLogoView_Previews: PreviewProvider {
    static var previews: some View {
        TMDBLogoView()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
