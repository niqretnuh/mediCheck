import SwiftUI
import PhotosUI
import FirebaseCore



class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}


/* ... */

struct ContentView: View {
    
    @State private var searchText: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?
    @State private var detectedText: String = "No text detected"
    @State private var medicationNames: [String] = ["No medications identified"]
    @State private var isCameraPresented = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let geminiAPI = GeminiAPI()  // Initialize Gemini API

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue.opacity(0.2)
                    .ignoresSafeArea()

                VStack {
                    Text("Which medication are you looking for?")
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

                        // Navigation Button
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

                    // Upload Medicine Picture
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
                    .padding()
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                recognizeText(in: uiImage) // Perform OCR and then fetch medication names
                            }
                        }
                    }

                    // Capture with Camera
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
                    .padding()
                    .sheet(isPresented: $isCameraPresented) {
                        CameraPicker(selectedImage: $selectedImage, onImagePicked: recognizeText)
                    }

                    // Box to show AI-processed medication names
                    GroupBox(label: Label("Identified Medications", systemImage: "pills")) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(medicationNames, id: \.self) { name in
                                Text("• \(name)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .padding(.horizontal)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                )
                .padding(40)
            }
            .navigationTitle("Medilocate")
            .navigationDestination(for: String.self) { searchQuery in
                PostSearchView(searchText: searchQuery)
            }
        }
        .overlay(alignment: .bottom) {
            BottomNavigationBar()
        }
    }

    func recognizeText(in image: UIImage) {
        TextRecognition.shared.recognizeText(in: image) { recognizedText in
            detectedText = recognizedText
            UserDefaults.standard.set(detectedText, forKey: "ocrResponse")
            
            LlamaAPI.query(text: recognizedText) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let responseText):
                        medicationNames = responseText.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    case .failure(let error):
                        print("Error querying LlamaAPI:", error.localizedDescription)
                        medicationNames = ["Error identifying medications"]
                    }
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
