import SwiftUI

struct PostSearchView: View {
    let searchResults: [String]
    
    var body: some View {
        VStack {
            Text("Search Results")
                .font(.title)
                .padding(.top)
            
            List(searchResults, id: \.self) { result in
                NavigationLink(destination: MedicineView(medication: result)) {
                    Text(result)
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PostSearchView(searchResults: ["Aspirin", "Ibuprofen", "Acetaminophen"])
    }
}
