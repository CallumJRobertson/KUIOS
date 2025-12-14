import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var isDeleting = false
    @State private var showConfirm = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Account")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(authManager.userEmail ?? "—")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()

            // Delete Account
            VStack(spacing: 12) {
                Text("Delete your account")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("Deleting your account will remove your authentication and local app data. This action cannot be undone. If you use Firebase auth, you may need to reauthenticate before deletion.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            
            Button(role: .destructive) {
                showConfirm = true
            } label: {
                if isDeleting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Delete Account")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .disabled(isDeleting)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Are you sure you want to delete your account? This action cannot be undone.", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    func performDelete() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found."
            return
        }

        isDeleting = true
        errorMessage = nil

        // Attempt to delete Firestore user document first (best-effort)
        if let uid = user.uid as String? {
            do {
                try await Firestore.firestore().collection("users").document(uid).delete()
            } catch {
                // Not fatal — log and continue with auth deletion
                print("Failed to delete Firestore user doc: \(error)")
            }
        }

        do {
            try await user.delete()
            // Sign out locally and clear app data
            authManager.signOut()
            appState.clearAllData()
            // Dismiss back to Settings
            dismiss()
        } catch {
            // If deletion fails due to recent login requirement, surface a helpful message
            let ns = error as NSError
            print("Account deletion error: \(ns)")
            if ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
                errorMessage = "Please re-authenticate (sign-out/sign-in) and try again."
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isDeleting = false
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView()
            .environmentObject(AuthManager())
            .environmentObject(AppState())
    }
}
