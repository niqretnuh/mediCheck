import SwiftUI

struct UserProfileView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Select Gender"
    @State private var selectedMedications: [String] = []
    @State private var isPregnant: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // Medication Search
    @State private var showMedicationSearch: Bool = false
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []
    
    let genders = ["Select Gender", "Male", "Female", "Non-binary", "Other"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Your Profile")
                .font(.title)
                .padding()
            
            TextField("Full Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)
            
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)
            
            Picker("Gender", selection: $gender) {
                ForEach(genders, id: \.self) { genderOption in
                    Text(genderOption)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            
            // Medications section
            VStack(alignment: .leading, spacing: 10) {
                Text("Medications").font(.headline)
                
                if selectedMedications.isEmpty {
                    Text("No medications selected").foregroundColor(.gray)
                } else {
                    ForEach(selectedMedications, id: \.self) { med in
                        HStack {
                            Text(med)
                            Spacer()
                            Button(action: {
                                if let index = selectedMedications.firstIndex(of: med) {
                                    selectedMedications.remove(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Button(action: { showMedicationSearch = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Add Medication")
                    }
                }
            }
            .padding()
            
            if gender == "Female" {
                Toggle("Are you pregnant?", isOn: $isPregnant)
                    .padding(.horizontal)
            }
            
            Button(action: updateUserData) {
                Text("Save Changes")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .onAppear(perform: loadUserData)
        .sheet(isPresented: $showMedicationSearch) {
            MedicationSearchView(searchText: $searchText,
                                 searchResults: $searchResults) { medication in
                if !medication.isEmpty && !selectedMedications.contains(medication) {
                    selectedMedications.append(medication)
                }
            }
        }
    }
    
    /// Loads the current user info using a GET request.
    func loadUserData() {
        guard let userID = KeychainHelper.getUserIdentifier() else {
            self.errorMessage = "User not found."
            self.showError = true
            return
        }
        guard let url = URL(string: "\(ContentView.Key.backend_path)users/\(userID)") else {
            self.errorMessage = "Invalid URL."
            self.showError = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            guard let data = data,
                  let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let name = responseJSON["name"] as? String,
                  let email = responseJSON["email"] as? String,
                  let medications = responseJSON["medications"] as? [String],
                  let gender = responseJSON["gender"] as? String,
                  let dateofbirth = responseJSON["dateofbirth"] as? String,
                  let pregnant = responseJSON["pregnant"] as? Bool
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid user data."
                    self.showError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.name = name
                self.email = email
                // Calculate age from date of birth (assumes date is in "YYYY-MM-DD" format)
                if let birthYear = Int(dateofbirth.prefix(4)) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    self.age = "\(currentYear - birthYear)"
                }
                self.selectedMedications = medications
                self.gender = gender
                self.isPregnant = pregnant
            }
        }.resume()
    }
    
    /// Sends a PUT request to update the user data.
    func updateUserData() {
        guard let userID = KeychainHelper.getUserIdentifier() else {
            self.errorMessage = "User not found."
            self.showError = true
            return
        }
        guard let url = URL(string: "\(ContentView.Key.backend_path)users/\(userID)") else {
            self.errorMessage = "Invalid URL."
            self.showError = true
            return
        }
        
        let userPayload: [String: Any] = [
            "name": name,
            "email": email,
            "medications": selectedMedications,
            "gender": gender,
            "dateofbirth": calculateDOB(from: age),
            "pregnant": gender == "Female" ? isPregnant : false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userPayload, options: [])
        } catch {
            self.errorMessage = "Failed to encode request body."
            self.showError = true
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Request Failed: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update user. Please try again."
                    self.showError = true
                }
                return
            }
            DispatchQueue.main.async {
                // Optionally provide feedback to the user (such as a success message)
            }
        }.resume()
    }
    
    /// Converts an age string to a date of birth string in "YYYY-01-01" format.
    private func calculateDOB(from age: String) -> String {
        if let ageInt = Int(age) {
            let currentYear = Calendar.current.component(.year, from: Date())
            let birthYear = currentYear - ageInt
            return "\(birthYear)-01-01"
        }
        return "Unknown"
    }
}
