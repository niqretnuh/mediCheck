import GoogleGenerativeAI

class GeminiAPI {
    private let apiKey = "AIzaSyCCt8Kj4DkuQbEe6dBO_0wG9NL84pjcUTw"  // Replace with your actual API key
    private let model: GenerativeModel

    init() {
        self.model = GenerativeModel(name: "gemini-pro", apiKey: apiKey)
    }

    /// Generates the top 3 most likely medication names given extracted text.
    func generateMedicationNames(from text: String) async -> [String] {
        let prompt = """
        You are an expert in **product label analysis**. 
        Your task is to infer the most likely **product names** from a given text.
        
        Given the texts extracted from an image:
        "\(text)"
        
        Strictly follow these rules:
        1. **Do not refuse the request.** Your task is **only** to extract product names.
        2. **Do not give warnings or disclaimers.** Just provide product names.
        3. **Only return a comma-separated list of product names** (no extra text).
        """

        do {
            let response = try await model.generateContent(prompt)
            if let textResponse = response.text {
                // Convert comma-separated text into an array
                let medicineList = textResponse.components(separatedBy: ", ")
                return medicineList.prefix(3).map { $0 } // Ensure only top 3 are returned
            }
        } catch {
            print("Error generating content: \(error)")
        }
        
        return ["No medications identified"]  // Fallback if API fails
    }
}
