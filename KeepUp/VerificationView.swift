import SwiftUI

struct VerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var message = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.1),
                         Color(red: 0.08, green: 0.1, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 70))
                    .foregroundStyle(.purple)
                
                Text("Verify your Email")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("We sent a verification link to:\n\(authManager.userEmail ?? "")")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                
                Button {
                    Task { await authManager.checkVerificationStatus() }
                } label: {
                    Text("I've Verified My Email")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
                
                Button("Resend Email") {
                    Task {
                        do {
                            try await authManager.resendVerificationEmail()
                            message = "Email sent!"
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
                .font(.callout)
                .foregroundStyle(.purple)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer().frame(height: 20)
                
                Button("Sign Out") {
                    authManager.signOut()
                }
                .foregroundStyle(.red)
            }
            .padding(40)
        }
    }
}
