import SwiftUI
import FirebaseCore
import GoogleSignIn

// MARK: - UIKit AppDelegate for Firebase & Google Sign-In
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - SwiftUI App

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var appState: AppState
    @StateObject private var authManager: AuthManager
    
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    init() {
        // Create shared AppState first…
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        // …and inject it into AuthManager
        _authManager = StateObject(wrappedValue: AuthManager(appState: appState))
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.userIsAuthenticated {
                    RootView()
                        .environmentObject(appState)
                } else {
                    LoginView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(appState)
            .preferredColorScheme(selectedScheme)
        }
    }
    
    private var selectedScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}
