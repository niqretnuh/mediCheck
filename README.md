# Medilocate

Medilocate is an iOS application that helps users identify over-the-counter (OTC) medications, check for drug interactions with their current prescriptions or health conditions, and set reminders for safe medication usage. It uses OCR to capture text from medication packaging, GPT-4 to identify the product and suggest alternatives, and the RxNorm API to check for potential interactions.

## Table of Contents
1. Features
2. Tech Stack
3. Architecture Overview
4. Prerequisites
5. Setup & Installation
6. Usage
7. Roadmap
8. Contributing
9. License
10. Disclaimer

## Features
- **User Enrollment**: Collects user’s age, gender, pregnancy status, and list of currently used medications.
- **Medication Identification**: Captures medication packaging via the device camera. Uses Apple’s Vision (OCR) to recognize text, then GPT-4 to identify the product and active ingredients.
- **Drug Interaction Checks**: Integrates with RxNorm to map ingredients to RxCUIs and checks for potential interactions with the user’s existing medications.
- **Alternative Suggestions**: GPT-4 suggests similar OTC products if the initial medication is unsafe.
- **Notifications**: Local notifications remind users to take their chosen medication at specified intervals.
- **Data Persistence**: Stores user profile and medication data locally (Core Data or Realm) for quick access.

## Tech Stack
- **Language & Framework**: Swift, SwiftUI
- **OCR**: Vision Framework (iOS)
- **GPT-4 Integration**: OpenAI API
- **Drug Interaction**: RxNorm / RxNav APIs
- **Local Notifications**: iOS UserNotifications framework
- **Data Persistence**: Core Data (or Realm, depending on preference)

## Architecture Overview
The app follows a **simplified MVVM structure** to separate business logic from UI layers:

### 1. Views (SwiftUI)
- `OnboardingView`, `ScanView`, `ResultsView`, `MedicationInfoView`, etc.

### 2. ViewModels
- Manage state and logic for each view.
- Orchestrate **network calls**, **local data reads/writes**, and **transformations** for UI.

### 3. Services
- **OCRService**: Wrapper around Apple's Vision framework for text recognition.
- **GPTService**: Handles API calls to **GPT-4** with **custom prompt engineering**.
- **RxNormService**: Maps product/ingredient data to **RxCUIs** and checks medication interactions.

### 4. Data Layer
- Stores **UserProfile** and **Medication** models in **Core Data** (or another local database solution).

### 5. Networking Layer
- `NetworkManager` to handle **requests, authentication, and response parsing** for **GPT-4** and **RxNorm** endpoints.

## Prerequisites
1. **Xcode (14+ recommended)**
2. **iOS Deployment Target**: iOS 15 or later (adjust based on your code)
3. **API Keys**
   - OpenAI API Key (for GPT-4)
   - RxNorm doesn’t strictly require a key but ensure you have the correct endpoint references.
4. **Swift Package Manager or CocoaPods** (for any 3rd party dependencies if needed).

## Setup & Installation
### 1. Clone the Repo
```sh
git clone https://github.com/YourUsername/Medilocate.git
cd Medilocate
```
### 2. Open in Xcode
- Double-click `Medilocate.xcodeproj` (or open `Medilocate.xcworkspace` if using CocoaPods).

### 3. Configure API Keys
Create a `Secrets.plist` or `.xcconfig` file (or use environment variables) containing your OpenAI API key.

**Example Secrets.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OpenAIAPIKey</key>
    <string>YOUR_API_KEY</string>
</dict>
</plist>
```
Ensure this file is ignored in `.gitignore` to prevent exposing sensitive data.

### 4. Dependencies
- If using **Swift Package Manager**, open Xcode → File → Add Packages → Add any necessary dependencies.

### 5. Build & Run
- Select your **Simulator or iOS device**.
- Click the **Run** button in Xcode.

## Usage
1. **Onboarding**: Upon first launch, the user inputs their age, gender, pregnancy status, and current medications.
2. **Scanning a Medication**: Tap **Scan** → capture/select a medication package image → OCR processes the text → GPT-4 identifies the product and its ingredients.
3. **Interaction Checks**: The app uses RxNorm to check interactions and displays a **Safe** or **Not Safe** result.
4. **Alternatives**: If unsafe, GPT-4 provides suggestions. The user can select a suggestion to re-run checks until finding a safe product.
5. **Reminders**: Users can set notifications for safe medication use.

## Roadmap
- **Short-Term**: Improve OCR accuracy, add manual input fallback.
- **Mid-Term**: Enhance error handling, refine UI/UX.
- **Long-Term**: Integrate with wearable health apps, expand to additional drug databases.

## Contributing
1. Fork this repository.
2. Create a feature branch:
   ```sh
   git checkout -b feature/amazing-feature
   ```
3. Commit changes:
   ```sh
   git commit -m 'Add some amazing feature'
   ```
4. Push to branch:
   ```sh
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request.

## License
**MIT License**
```
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files...
```

## Disclaimer
- **Not Medical Advice**: This app is informational only and does not replace professional medical guidance.
- **Data Privacy**: User data privacy is taken seriously. See our Privacy Policy for details.
- **Liability**: The app developers are not liable for adverse outcomes from medication use.

---
Thank you for using **Medilocate**! If you have any questions or suggestions, feel free to open an issue or reach out via email.

