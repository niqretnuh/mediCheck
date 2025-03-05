import SwiftUI

@main
struct MedilocateApp: App {
    // Always require login on app launch
    @State private var isAuthenticated: Bool = false
    // Check if the user’s profile is complete.
    @State private var hasProfile: Bool = false

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
