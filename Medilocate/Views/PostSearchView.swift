import SwiftUI

struct PostSearchView: View {
    @State private var searchText: String
    @State private var results: [String] = []
    
    init(searchText: String) {
        _searchText = State(initialValue: searchText)
        _results = State(initialValue: fetchResults(for: searchText))
    }
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                TextField("Enter medication name...", text: $searchText, onCommit: {
                    results = fetchResults(for: searchText)
                })
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 1)
                
                Button(action: {
                    results = fetchResults(for: searchText)
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Display Results
            List(results, id: \.self) { item in
                Text(item)
                    .padding()
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Search Results")
    }
}

// Function to simulate fetching results
func fetchResults(for query: String) -> [String] {
    guard !query.isEmpty else { return [] }
    return ["Medication " + query].filter { $0.localizedCaseInsensitiveContains(query) }
}

#Preview {
    PostSearchView(searchText: "Tylenol")
}
