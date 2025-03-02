import SwiftUI

struct UserProfileView: View {
    @State private var username: String = "Loading..."
    @State private var email: String = "Loading..."
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding()
                
                // User Info
                Text(username)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Settings
                List {
                    NavigationLink(destination: Text("Account Settings")) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Account Settings")
                        }
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Privacy Policy")
                        }
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Help & Support")
                        }
                    }
                    
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                Spacer()
                
                // Bottom Navigation Bar
                VStack {
                    Spacer()
                    HStack {
                        NavigationLink(destination: ContentView()) {
                            VStack {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        NavigationLink(destination: UserProfileView()) {
                            VStack {
                                Image(systemName: "person.fill")
                                Text("Profile")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                }
                .navigationTitle("Profile")
            }
        }
        .onAppear {
            loadUserData() // Fetch user info when the view appears
        }
    }
    
    // Loads user data from Keychain or UserDefaults
    private func loadUserData() {
        if let userID = KeychainHelper.getUserIdentifier() {
            username = "User ID: \(userID)" // Replace with actual user details
        }
        
        // Retrieve stored email if available
        if let storedEmail = UserDefaults.standard.string(forKey: "userEmail") {
            email = storedEmail
        }
    }
    
    // Logs out the user and resets stored data
    private func logout() {
        KeychainHelper.deleteUserIdentifier() // Remove stored login info
        UserDefaults.standard.removeObject(forKey: "userEmail") // Remove email
        username = "Guest"
        email = "Not logged in"
    }
}

#Preview {
    UserProfileView()
}
