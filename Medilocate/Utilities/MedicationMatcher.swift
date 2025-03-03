import Foundation

class MedicationMatcher {
    /// Calls the backend API to find the closest medication matches based on the query.
    /// - Parameters:
    ///   - query: The medication search query.
    ///   - k: The number of results to return (default is 3).
    ///   - completion: Completion handler with an array of matched medication names.
    func findClosestMedications(for query: String, k: Int = 3, completion: @escaping ([String]) -> Void) {

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(ContentView.Key.backend_path)medications?query=\(encodedQuery)&k=\(k)") else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching medication matches: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [String] {
                    completion(results)
                } else {
                    completion([])
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion([])
            }
        }
        task.resume()
    }
}
