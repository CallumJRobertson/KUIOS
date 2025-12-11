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
    @Published var userID: String?
    @Published var userEmail: String?
    
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    // ✅ Direct reference to AppState instead of fishing through AppDelegate
    private weak var appState: AppState?
    
    init(appState: AppState? = nil) {
        self.appState = appState
        
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    // User is signed in
                    self.userID = user.uid
                    self.userEmail = user.email
                    self.userIsAuthenticated = true
                    
                    // Load user data into AppState
                    self.loadUserData(userID: user.uid)
                } else {
                    // User is signed out
                    self.userID = nil
                    self.userEmail = nil
                    self.userIsAuthenticated = false
                    
                    // Clear app data
                    self.clearUserData()
                }
            }
        }
    }
    
    // MARK: - AppState helpers
    
    private func loadUserData(userID: String) {
        guard let appState = appState else {
            print("⚠️ AuthManager: appState is not set")
            return
        }
        print("✅ Loading tracked shows for user: \(userID)")
        appState.loadTrackedShows(forUserID: userID)
    }
    
    private func clearUserData() {
        guard let appState = appState else { return }
        print("🗑️ Clearing user data")
        appState.clearAllData()
    }
    
    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out")
        } catch let signOutError as NSError {
            print("❌ Error signing out: \(signOutError)")
        }
    }
    
    // MARK: - Sign in with Google
    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No client ID found in Firebase configuration")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(
                    domain: "AuthManager",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "ID Token missing"]
                )
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            _ = try await Auth.auth().signIn(with: credential)
            print("✅ Google Sign-In successful")
        } catch {
            print("❌ Google Sign-In Error: \(error.localizedDescription)")
        }
    }
}
