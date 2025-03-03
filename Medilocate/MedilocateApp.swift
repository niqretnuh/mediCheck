//
//  MedilocateApp.swift
//  Medilocate
//
//  Created by Haoran 22. Qin on 2/3/25.
//

import SwiftUI

@main
struct MedilocateApp: App {
    @State private var isAuthenticated: Bool = KeychainHelper.getUserIdentifier() != nil
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
            }
            else {
                OnboardingView()
            }
        }
    }
}
