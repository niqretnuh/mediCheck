import SwiftUI
import PhotosUI

struct ContentView: View {
    /// TODO: This is stupid. Jimmy please get backend done
    @State private var searchText: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?
    @State private var detectedText: String = "No text detected"
    
    // State control vars
    @State private var searchResults: [String]? = nil
    @State private var navigateToPostSearch = false
    /// TODO: This is also stupid and needs to go
    private let finder = MedicationMatcher(csvFileName: "unique_prod_names")
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Which medication are you looking for?")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    
                    // Search Bar
                    HStack {
                        TextField("Enter medication name...", text: $searchText)
                            .padding()
                            .frame(width: 280, height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        
                        Button(action: performSearch) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(searchText.isEmpty)
                    }
                    
                    // Upload Pic
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Upload Medicine Picture")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                recognizeText(in: uiImage)
                            }
                        }
                    }
                    
                    // Take pic
                    Button(action: {
                        isCameraPresented.toggle()
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Take a Picture")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .sheet(isPresented: $isCameraPresented) {
                        CameraPicker(selectedImage: $selectedImage, onImagePicked: recognizeText)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                )
                .padding(40)
                
                // State variables trigger Navigation to postsearch
                NavigationLink(
                    destination: PostSearchView(searchResults: searchResults ?? []),
                    isActive: $navigateToPostSearch,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .navigationTitle("Medilocate")
        }
        .overlay(
                    BottomNavigationBar(),
                    alignment: .bottom
                )
    }
    
    // Uses OCR to recognize text from an image, then finds the closest medication names.
    func recognizeText(in image: UIImage) {
        // Immediately dismiss the camera view on the main thread.
        DispatchQueue.main.async {
            isCameraPresented = false
        }

        TextRecognition.shared.recognizeText(in: image) { recognizedText in
            // split recognized text, and choose top 3
            let candidates = recognizedText.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let topCandidates = candidates.prefix(3)
            let query = topCandidates.joined(separator: " ")
            
            detectedText = query
            UserDefaults.standard.set(detectedText, forKey: "ocrResponse")
            
            // call knn matching function
            let results = finder.findClosestMedications(for: detectedText, k: 3)
            DispatchQueue.main.async {
                searchResults = results
                navigateToPostSearch = true
            }
        }
    }


    
    // Performs a search using the text in the search bar.
    func performSearch() {
        let results = finder.findClosestMedications(for: searchText, k: 3)
        searchResults = results
        navigateToPostSearch = true
    }
    
    @State private var isCameraPresented = false
}

#Preview {
    ContentView()
}
