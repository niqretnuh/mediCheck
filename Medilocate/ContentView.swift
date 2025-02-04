import SwiftUI

struct ContentView: View {
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue.opacity(0.2)
                    .ignoresSafeArea()

                VStack {
                    Text("Which medication are you looking to take?")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)

                    // Search Bar
                    HStack {
                        TextField("Enter medication name...", text: $searchText)
                            .padding()
                            .frame(width: 280, height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)

                        // Navigation
                        NavigationLink(value: searchText) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(searchText.isEmpty) // Prevent navigation if empty
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
                .padding(40)
            }
            .navigationTitle("Medilocate")

            // Destination View for Navigation
            .navigationDestination(for: String.self) { searchQuery in
                PostSearchView(searchText: searchQuery)
            }
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
            .navigationTitle("Medilocate")
        }
    }
}

#Preview {
    ContentView()
}
