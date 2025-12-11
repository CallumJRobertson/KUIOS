import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15),
                         Color(red: 0.1, green: 0.1, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                Image(systemName: "sparkles.tv")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan)
                    .padding(.bottom, 20)
                
                Text("Welcome to KeepUp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Securely save your tracking list to the cloud using your SSO provider.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {

                    // MARK: - Sign in with Google
                    GoogleSignInButton(
                        action: {
                            Task { await authManager.signInWithGoogle() }
                        }
                    )
                    .tint(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 40)
            }
        }
    }
}
