import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    
    var body: some View {
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
            checkExistingAppleIDCredential()
        }
    }
    
    /// Handles Apple Sign-In success.
    private func handleSignIn(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            KeychainHelper.save(userIdentifier: userIdentifier)
            
            // Optionally, store the email if provided.
            if let email = appleIDCredential.email {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            // Here you can add logic to determine if the user’s profile is complete.
            // For example, if no extra profile info exists, you might consider it incomplete.
            // In this example, we simply update authentication here.
            DispatchQueue.main.async {
                isAuthenticated = true
            }
        }
    }
    
    /// Checks if the user is already signed in.
    private func checkExistingAppleIDCredential() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainHelper.getUserIdentifier() ?? "") { state, _ in
            if state == .authorized {
                DispatchQueue.main.async {
                    isAuthenticated = true
                }
            }
            else{
                isAuthenticated = false
            }
        }
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
}
