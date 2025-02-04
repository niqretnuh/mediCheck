import SwiftUI

struct PostSearchView: View {

    var searchText: String// Expecting a string from ContentView

    var body: some View {
        VStack {
            Text("Results for: \(searchText)")
                .font(.title2)
                .padding()

            Spacer()
        }
        .navigationTitle("Search Results")
    }
}

