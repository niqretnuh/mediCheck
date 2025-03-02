import SwiftUI

struct OnboardingView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Select Gender"
    @State private var medications: String = ""
    @State private var isPregnant: Bool = false
    @State private var isAuthenticated: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let genders = ["Select Gender", "Male", "Female", "Non-binary", "Other"]

    var body: some View {
        if isAuthenticated {
            ContentView() // ✅ Switches to main screen after successful onboarding
        } else {
            VStack(spacing: 20) {
                Text("Welcome to Medicheck! Enter your details to create a profile.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()

                // Name
                TextField("Full Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Email
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()

                // Age
                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()

                // Gender Picker
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { Text($0) }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                // Medications
                TextField("Current Medications (comma-separated)", text: $medications)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Pregnancy Status (Only for Female)
                if gender == "Female" {
                    Toggle("Are you pregnant?", isOn: $isPregnant)
                        .padding()
                }

                // Submit Button
                Button(action: submitUserData) {
                    Text("Create Profile")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(name.isEmpty || email.isEmpty || age.isEmpty || gender == "Select Gender")

                // Error Message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
    }

    /// **Submits User Data to MongoDB Backend**
    private func submitUserData() {
        guard let url = URL(string: "http://localhost:8888/api/users") else {
            self.errorMessage = "Invalid API URL"
            self.showError = true
            return
        }

        let userPayload: [String: Any] = [
            "name": name,
            "email": email,
            "medications": medications.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "gender": gender,
            "dateofbirth": calculateDOB(from: age),
            "pregnant": gender == "Female" ? isPregnant : false
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userPayload, options: [])
        } catch {
            self.errorMessage = "Failed to encode request body"
            self.showError = true
            return
        }

        // **Send Data to API**
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Request Failed: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201,
                  let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create user. Please try again."
                    self.showError = true
                }
                return
            }

            // **User Successfully Created**
            DispatchQueue.main.async {
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let user = responseJSON["user"] as? [String: Any],
                       let userID = user["_id"] as? String {
                        
                        // ✅ Store User ID in Keychain
                        KeychainHelper.save(userIdentifier: userID)
                        
                        // ✅ Save Email for Future Login
                        UserDefaults.standard.set(email, forKey: "userEmail")
                        
                        // ✅ Navigate to `ContentView`
                        isAuthenticated = true
                    }
                } catch {
                    self.errorMessage = "Error processing server response"
                    self.showError = true
                }
            }
        }.resume()
    }

    /// **Calculates Date of Birth from Age**
    private func calculateDOB(from age: String) -> String {
        if let ageInt = Int(age) {
            let currentYear = Calendar.current.component(.year, from: Date())
            let birthYear = currentYear - ageInt
            return "\(birthYear)-01-01" // Approximate DOB
        }
        return "Unknown"
    }
}

#Preview {
    OnboardingView()
}
