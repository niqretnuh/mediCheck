import SwiftUI
import PhotosUI

struct MedicineView: View {
    let medication: String
    @State private var bulletPoints: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var navigateToInteractions = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue.opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    if isLoading {
                        ProgressView("Loading FDA translation...")
                            .padding()
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        List(bulletPoints, id: \.self) { bullet in
                            Text(bullet)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle(medication)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Medication") {
                            navigateToInteractions = true
                        }
                    }
                }
                .onAppear {
                    fetchFDATranslation()
                }
                // NavigationLink to the next page (InteractionsView)
                NavigationLink(
                    destination: InteractionsView(medication: medication),
                    isActive: $navigateToInteractions,
                    label: { EmptyView() }
                )
                .hidden()
            }
        }
    }
    
    /// Splits the generated text by newline, trims each line, and filters out empty lines.
    func processGeneratedText(_ text: String) -> [String] {
        return text.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
    }
    
    /// Fetches FDA translation from the backend and processes it into an array of lines.
    func fetchFDATranslation() {
        guard let encodedMedication = medication.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(ContentView.Key.backend_path)fda_translate?medication=\(encodedMedication)&max_new_tokens=256&top_p=0.9&temperature=0.6")
        else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                    self.isLoading = false
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var generatedText: String = ""
                    if let text = json["generated_text"] as? String {
                        generatedText = text
                        print("Generated Text: \(generatedText)")
                    } else {
                        generatedText = String(data: data, encoding: .utf8) ?? ""
                    }
                    
                    // Process the generated text line by line.
                    let processedLines = processGeneratedText(generatedText)
                    DispatchQueue.main.async {
                        self.bulletPoints = processedLines
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

struct MedicineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicineView(medication: "Aspirin")
        }
    }
}
