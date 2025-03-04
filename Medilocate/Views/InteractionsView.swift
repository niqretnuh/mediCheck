import SwiftUI

struct InteractionsView: View {
    let medication: String
    @State private var interactions: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Checking interactions...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                if interactions.isEmpty {
                    Text("No interactions detected.")
                        .padding()
                    Button("Confirm Add Medication", action: addMedication)
                        .padding()
                } else {
                    Text("Potential Drug Interactions:")
                        .font(.headline)
                        .padding(.top)
                    List(interactions, id: \.self) { interaction in
                        Text(interaction)
                            .padding(.vertical, 4)
                    }
                    Button("Proceed Anyway", action: addMedication)
                        .padding()
                }
            }
        }
        .navigationTitle("Interactions for \(medication)")
        .onAppear {
            fetchInteractions()
        }
    }
    
    func fetchInteractions() {
        // Retrieve user identifier from Keychain
        guard let userId = KeychainHelper.getUserIdentifier() else {
            self.errorMessage = "User not found"
            self.isLoading = false
            return
        }
        
        guard let encodedMedication = medication.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(ContentView.Key.backend_path)interactions?user_id=\(userId)&medication=\(encodedMedication)")
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let interactionsArray = json["generated_text"] as? [String] {
                    DispatchQueue.main.async {
                        self.interactions = interactionsArray
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unexpected response format"
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
    
    func addMedication() {
        // Build the URL for the PATCH request to update medications.
        guard let userId = KeychainHelper.getUserIdentifier() else {
            print("User ID not found in Keychain")
            return
        }
        guard let url = URL(string: "\(ContentView.Key.backend_path)users/\(userId)/medications") else {
            print("Invalid URL for updating medications")
            return
        }
        
        let body: [String: Any] = [
            "medicationsToAdd": [medication],
            "medicationsToRemove": []
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating medication: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received when updating medication")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Medication update response: \(json)")
                }
            } catch {
                print("Error parsing medication update response: \(error)")
            }
        }.resume()
    }
}

struct InteractionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InteractionsView(medication: "Aspirin")
        }
    }
}
