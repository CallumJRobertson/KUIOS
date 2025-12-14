import Foundation
import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AuthManager: ObservableObject {
    @Published var userIsAuthenticated: Bool = false
    @Published var isEmailVerified: Bool = false // ✅ Track verification
    @Published var userID: String?
    @Published var userEmail: String?
    
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    private weak var appState: AppState?
    
    init(appState: AppState? = nil) {
        self.appState = appState
        
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    self.userID = user.uid
                    self.userEmail = user.email
                    self.userIsAuthenticated = true
                    self.isEmailVerified = user.isEmailVerified // ✅ Check status
                    
                    // Load user data regardless of email verification so UI (Updates) can show tracked shows.
                    // Verification gating remains for sensitive features, but tracked data should be visible.
                    self.loadUserData(userID: user.uid)
                } else {
                    self.userID = nil
                    self.userEmail = nil
                    self.userIsAuthenticated = false
                    self.isEmailVerified = false
                    self.clearUserData()
                }
            }
        }
    }
    
    // MARK: - Email/Password Auth
    
    func signUp(email: String, pass: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: pass)
        // ✅ Send verification email immediately after sign up
        try await result.user.sendEmailVerification()
    }

    func signIn(email: String, pass: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: pass)
        // authStateDidChangeListener will update flags
    }
    
    // ✅ Helper to refresh status (User clicks this after verifying)
    func checkVerificationStatus() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await user.reload() // Pings Firebase to get fresh status
            self.isEmailVerified = user.isEmailVerified
            
            if self.isEmailVerified {
                self.loadUserData(userID: user.uid)
            }
        } catch {
            print("Error reloading user: \(error)")
        }
    }
    
    // ✅ Resend link if they lost it
    func resendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }
    
    // MARK: - AppState helpers
    
    private func loadUserData(userID: String) {
        guard let appState = appState else { return }
        appState.loadTrackedShows(forUserID: userID)
    }
    
    private func clearUserData() {
        guard let appState = appState else { return }
        appState.clearAllData()
    }
    
    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    func signInWithGoogle() async {
        // Google accounts are automatically "verified"
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            guard let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            _ = try await Auth.auth().signIn(with: credential)
        } catch {
            print("Google Sign-In Error: \(error.localizedDescription)")
        }
    }
}
