import SwiftUI

struct PostSearchView: View {
    let searchResults: [String]
    
    var body: some View {
        VStack {
            Text("Search Results")
                .font(.title)
                .padding(.top)
            
            List(searchResults, id: \.self) { result in
                Text(result)
                    .font(.headline)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PostSearchView(searchResults: ["Medication 1", "Medication 2", "Medication 3"])
}
