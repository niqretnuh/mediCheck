import SwiftUI

@main
struct MedilocateApp: App {
    // Check if the user is authenticated via Apple ID.
    @State private var isAuthenticated: Bool = KeychainHelper.getUserIdentifier() != nil
    // Check if the user’s profile is complete.
    @State private var hasProfile: Bool = UserDefaults.standard.bool(forKey: "hasProfile")
    
    var body: some Scene {
        WindowGroup {
            if !isAuthenticated {
                // Show LoginView if not authenticated.
                LoginView(isAuthenticated: $isAuthenticated)
            } else if !hasProfile {
                // Route to OnboardingView if the profile isn’t set up.
                OnboardingView(hasProfile: $hasProfile)
            } else {
                // Otherwise, go straight to ContentView.
                ContentView()
            }
        }
    }
}
