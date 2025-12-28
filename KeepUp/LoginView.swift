import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // ✅ NEW: State for email/password input
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.1),
                         Color(red: 0.08, green: 0.1, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    Spacer().frame(height: 40)
                    
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 80))
                        .foregroundStyle(.purple)
                        .padding(.bottom, 10)
                    
                    Text("Welcome to KeepUp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Securely save your tracking list to the cloud.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // MARK: - Email & Password Section
                    VStack(spacing: 16) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                        
                        if isLoading {
                            ProgressView()
                                .tint(.purple)
                        } else {
                            HStack(spacing: 16) {
                                Button {
                                    handleAction(isSignUp: true)
                                } label: {
                                    Text("Sign Up")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.purple, lineWidth: 1)
                                        )
                                }
                                
                                Button {
                                    handleAction(isSignUp: false)
                                } label: {
                                    Text("Log In")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // MARK: - Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.3))
                        Text("OR").font(.caption).foregroundStyle(.white.opacity(0.7))
                        Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    
                    // MARK: - Google Sign In
                    VStack(spacing: 16) {
                        GoogleSignInButton(
                            scheme: .light,
                            style: .wide,
                            action: {
                                Task { await authManager.signInWithGoogle() }
                            }
                        )
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
    
    // Helper function to handle auth calls
    func handleAction(isSignUp: Bool) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, pass: password)
                } else {
                    try await authManager.signIn(email: email, pass: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
