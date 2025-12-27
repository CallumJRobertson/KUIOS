import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var isDeleting = false
    @State private var isUpdatingEmail = false
    @State private var isUpdatingPassword = false
    @State private var isRefreshing = false
    @State private var isResending = false
    @State private var showConfirm = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var newEmail: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authManager.userEmail ?? "—")
                        Label(authManager.isEmailVerified ? "Verified" : "Not Verified", systemImage: authManager.isEmailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(authManager.isEmailVerified ? .green : .orange)
                            .font(.caption)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button("Refresh") { Task { await refreshStatus() } }
                            .disabled(isRefreshing)
                        Button("Resend Email") { Task { await resendVerification() } }
                            .disabled(isResending)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Change Email") {
                TextField("New email", text: $newEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button {
                    Task { await updateEmail() }
                } label: {
                    if isUpdatingEmail { ProgressView() } else { Text("Update Email") }
                }
                .disabled(isUpdatingEmail || newEmail.isEmpty)
            }

            Section("Change Password") {
                SecureField("New password", text: $newPassword)
                SecureField("Confirm password", text: $confirmPassword)
                Button {
                    Task { await updatePassword() }
                } label: {
                    if isUpdatingPassword { ProgressView() } else { Text("Update Password") }
                }
                .disabled(isUpdatingPassword || newPassword.isEmpty || confirmPassword.isEmpty)
            }

            Section("Session") {
                Button("Sign Out", role: .none) {
                    authManager.signOut()
                    dismiss()
                }
                .foregroundColor(.red)
            }

            Section("Danger Zone") {
                Text("Deleting your account removes authentication and local app data. You may need to re-authenticate if Firebase requires a recent login.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(role: .destructive) {
                    showConfirm = true
                } label: {
                    if isDeleting { ProgressView() } else { Text("Delete Account") }
                }
                .disabled(isDeleting)
            }

            if let info = infoMessage {
                Section { Text(info).foregroundColor(.green) }
            }
            if let error = errorMessage {
                Section { Text(error).foregroundColor(.red) }
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Are you sure you want to delete your account? This action cannot be undone.", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    func refreshStatus() async {
        errorMessage = nil
        infoMessage = nil
        isRefreshing = true
        do {
            try await authManager.refreshUser()
            infoMessage = authManager.isEmailVerified ? "Email verified." : "Verification pending."
        } catch {
            errorMessage = error.localizedDescription
        }
        isRefreshing = false
    }

    func resendVerification() async {
        errorMessage = nil
        infoMessage = nil
        isResending = true
        do {
            try await authManager.resendVerificationEmail()
            infoMessage = "Verification email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
        isResending = false
    }

    func updateEmail() async {
        guard !newEmail.isEmpty else { return }
        errorMessage = nil
        infoMessage = nil
        isUpdatingEmail = true
        do {
            try await authManager.updateEmail(to: newEmail)
            infoMessage = "Email updated."
            newEmail = ""
        } catch {
            let ns = error as NSError
            if ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
                errorMessage = "Please sign out/in, then try updating your email again."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isUpdatingEmail = false
    }

    func updatePassword() async {
        guard !newPassword.isEmpty, newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        errorMessage = nil
        infoMessage = nil
        isUpdatingPassword = true
        do {
            try await authManager.updatePassword(to: newPassword)
            infoMessage = "Password updated."
            newPassword = ""
            confirmPassword = ""
        } catch {
            let ns = error as NSError
            if ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
                errorMessage = "Please sign out/in, then try updating your password again."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isUpdatingPassword = false
    }

    func performDelete() async {
        isDeleting = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await authManager.deleteAccount()
            dismiss()
        } catch {
            let ns = error as NSError
            if ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
                errorMessage = "Please re-authenticate (sign out/in) then delete again."
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
