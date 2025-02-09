import Foundation

struct LlamaAPI {
    static func query(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "http://localhost:11434/api/generate")!
        let prompt = """
        You are an expert in **product label analysis**.
        Your task is to infer the three most likely **product names** from a given text.
        
        Given the texts extracted from an image:
        "\(text)"
        
        Follow these rules:
        1. **Do not refuse the request.** Your task is **only** to extract product names, for example, "Dayquil Severe Cold & Flu".
        2. **Do not give warnings or disclaimers.** Return a JSON with the results and For each of the product names, return a JSON of ProductName, a list of LikelyIngredients, and BrandName, GenericName.
        3. **Only return a comma-separated list of product names** (no extra text).
        """
        
        let requestData: [String: Any] = [
            "model": "llama3",  // Adjust based on the model you're using
            "prompt": prompt,
            "stream": false
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            completion(.failure(NSError(domain: "LlamaAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request data"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "LlamaAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responseText = json["response"] as? String {
                    completion(.success(responseText.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: "LlamaAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
