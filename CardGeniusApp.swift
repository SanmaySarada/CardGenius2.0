//
//  CardGeniusApp.swift
//  CardGenius
//
//  Created on iOS 17+
//

import SwiftUI

@main
struct CardGeniusApp: App {
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var serviceContainer = ServiceContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(serviceContainer)
                .preferredColorScheme(.light) // Can be changed to .dark or nil for system
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                OnboardingFlowView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appState.isOnboarded)
    }
}

// MARK: - App State View Model
@MainActor
class AppStateViewModel: ObservableObject {
    @Published var isOnboarded: Bool = false
    
    init() {
        // In production, check UserDefaults or keychain
        // For now, default to false to show onboarding
        isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
    }
    
    func completeOnboarding() {
        isOnboarded = true
        UserDefaults.standard.set(true, forKey: "isOnboarded")
    }
    
    func resetOnboarding() {
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "isOnboarded")
    }
}

