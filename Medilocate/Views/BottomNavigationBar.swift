import SwiftUI

struct BottomNavigationBar: View {
    var body: some View {
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
}


