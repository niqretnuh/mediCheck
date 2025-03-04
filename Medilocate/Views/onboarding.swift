import SwiftUI

struct OnboardingView: View {
    @Binding var hasProfile: Bool
    @State private var name: String = ""
    @State private var email: String = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var age: String = ""
    @State private var gender: String = "Select Gender"
    @State private var selectedMedications: [String] = []
    @State private var isPregnant: Bool = false
    @State private var isAuthenticated: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // Medication Search
    @State private var showMedicationSearch: Bool = false
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []

    let genders = ["Select Gender", "Male", "Female", "Non-binary", "Other"]

    var body: some View {
        if isAuthenticated {
            ContentView() // Switches to main screen after successful onboarding
        } else {
            VStack(spacing: 20) {
                Text("Welcome to Medicheck! Enter your details to create a profile.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()

                TextField("Full Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()

                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()

                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { genderOption in
                        Text(genderOption)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

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
                    Toggle("Are you pregnant?", isOn: $isPregnant).padding()
                }

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

                if showError {
                    Text(errorMessage).foregroundColor(.red).multilineTextAlignment(.center).padding()
                }
            }
            .padding()
            .sheet(isPresented: $showMedicationSearch) {
                MedicationSearchView(searchText: $searchText, searchResults: $searchResults) { medication in
                    if !medication.isEmpty && !selectedMedications.contains(medication) {
                        selectedMedications.append(medication)
                    }
                }
            }
        }
    }

    private func submitUserData() {
        guard let url = URL(string: "\(ContentView.Key.backend_path)users") else {
            self.errorMessage = "Invalid API URL"
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
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userPayload, options: [])
        } catch {
            self.errorMessage = "Failed to encode request body"
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
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create user. Please try again."
                    self.showError = true
                }
                return
            }

            DispatchQueue.main.async {
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let user = responseJSON["user"] as? [String: Any],
                       let userID = user["id"] as? String {
                        KeychainHelper.save(userIdentifier: userID)
                        UserDefaults.standard.set(email, forKey: "userEmail")
                        isAuthenticated = true
                        UserDefaults.standard.set(true, forKey: "hasProfile")
                        hasProfile = true
                    }
                } catch {
                    self.errorMessage = "Error processing server response"
                    self.showError = true
                }
            }
        }.resume()
    }

    private func calculateDOB(from age: String) -> String {
        if let ageInt = Int(age) {
            let currentYear = Calendar.current.component(.year, from: Date())
            let birthYear = currentYear - ageInt
            return "\(birthYear)-01-01"
        }
        return "Unknown"
    }
}

struct MedicationSearchView: View {
    @Binding var searchText: String
    @Binding var searchResults: [String]
    var onSelectMedication: (String) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search Medication", text: $searchText, onCommit: performSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Search", action: performSearch).padding(.bottom)

                List(searchResults, id: \.self) { medication in
                    Button(action: {
                        onSelectMedication(medication)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(medication)
                    }
                }
            }
            .navigationTitle("Search Medications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func performSearch() {
        let finder = MedicationMatcher()
        finder.findClosestMedications(for: searchText) { results in
            DispatchQueue.main.async {
                searchResults = results
            }
        }
    }
}

struct MedicationResponse: Codable {
    let results: [String]
}

#Preview {
    OnboardingView(hasProfile:.constant(false) )
}
