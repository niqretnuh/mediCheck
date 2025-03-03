import SwiftUI

struct MedicineView: View {
    let medication: String
    @State private var bulletPoints: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
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
        .onAppear {
            fetchFDATranslation()
        }
    }
    
    func fetchFDATranslation() {
        print(ContentView.Key.backend_path)
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
                    var resultText: String = ""
                    if let generatedText = json["generated_text"] as? String {
                        resultText = generatedText
                        print(resultText)
                    } else {
                        resultText = String(data: data, encoding: .utf8) ?? ""
                    }
                    // Split the generated text into bullet points
                    let bullets = resultText
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    DispatchQueue.main.async {
                        self.bulletPoints = bullets
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

struct FDAResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedicineView(medication: "Aspirin")
        }
    }
}
