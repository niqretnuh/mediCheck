import Foundation

class MedicationMatcher {
    func findClosestMedications(for query: String, k: Int = 1, completion: @escaping ([String]) -> Void) {

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
