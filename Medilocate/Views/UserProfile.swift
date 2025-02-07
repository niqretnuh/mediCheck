import SwiftUI

struct UserProfileView: View {
    @State private var username: String = "John Doe"
    @State private var email: String = "johndoe@example.com"
    
    var body: some View {
        ZStack{Color.white
                .ignoresSafeArea()
            
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
                }
                .frame(maxHeight: 300)
                
                Spacer()
                
                // Bottom Navigation Bar
                VStack {
                    Spacer()
                    // Bottom Navigation Bar
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
    }
}

#Preview {
    UserProfileView()
}
