import SwiftUI
import PhotosUI

struct MedicineView: View {
    let medication: String
    @State private var bulletViews: [Text] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var navigateToInteractions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading FDA Data...")
                            .padding()
                    } else if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(0..<bulletViews.count, id: \.self) { index in
                                    bulletViews[index]
                                        .padding(.vertical, 4)
                                }
                            }
                            .padding()
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
                NavigationLink(
                    destination: InteractionsView(medication: medication),
                    isActive: $navigateToInteractions,
                    label: { EmptyView() }
                )
                .hidden()
            }
        }
    }
    
    // Manually split the generated text into lines
    func processGeneratedText(_ text: String) -> [Text] {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let bulletMarkers: Set<Character> = ["*", "-", "+"]
        let bulletLines: [String] = {
            if let first = lines.first, let firstChar = first.first, !bulletMarkers.contains(firstChar) {
                return Array(lines.dropFirst())
            } else {
                return lines
            }
        }()
        
        return bulletLines.map { parseBulletLine($0) }
    }
    
    
    func parseBulletLine(_ line: String) -> Text {
        // Remove any leading bullet marker and whitespace.
        var workingLine = line
        if let first = workingLine.first, ["*", "-", "+"].contains(first) {
            workingLine.removeFirst()
            workingLine = workingLine.trimmingCharacters(in: .whitespaces)
        }
        
        // Now, manually process bold markers (i.e., **text**).
        let parts = workingLine.components(separatedBy: "**")
        var formattedText = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                formattedText = formattedText + Text(part)
            } else {
                formattedText = formattedText + Text(part).bold()
            }
        }
        return formattedText
    }
    
    func fetchFDATranslation() {
        guard let userId = KeychainHelper.getUserIdentifier() else {
            self.errorMessage = "User not found"
            self.isLoading = false
            return
        }
        guard let encodedMedication = medication.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(ContentView.Key.backend_path)fda_translate?user_id=\(userId)&medication=\(encodedMedication)&max_new_tokens=256&top_p=0.9&temperature=0.6")
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
                    
                    let formattedLines = processGeneratedText(generatedText)
                    DispatchQueue.main.async {
                        self.bulletViews = formattedLines
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
