import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            ContentView() // ✅ Automatically switches to ContentView after login
        } else {
            VStack {
                Text("Welcome to Medicheck! Click below to get started!")
                    .font(.title2)
                    .padding(.bottom, 20)

                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            handleSignIn(authResults)
                        case .failure(let error):
                            print("Authorization failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 250, height: 50)
                .cornerRadius(10)
                .padding()
            }
            .onAppear {
                checkExistingAppleIDCredential() // ✅ Auto-login if user was already authenticated
            }
        }
    }

    /// Handles Apple Sign-In success
    private func handleSignIn(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            KeychainHelper.save(userIdentifier: userIdentifier)

            if let email = appleIDCredential.email {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }

            DispatchQueue.main.async {
                isAuthenticated = true // ✅ Switch to ContentView
            }
        }
    }

    /// Checks if user is already signed in and switches to `ContentView`
    private func checkExistingAppleIDCredential() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainHelper.getUserIdentifier() ?? "") { state, _ in
            if state == .authorized {
                DispatchQueue.main.async {
                    isAuthenticated = true // ✅ Automatically switch to ContentView if already signed in
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
