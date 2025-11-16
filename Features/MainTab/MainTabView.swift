//
//  MainTabView.swift
//  CardGenius
//
//  Main Tab Bar Navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @State private var selectedTab: Int = 0
    @State private var showingSettings: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WalletTabView()
                .tabItem {
                    Label("Wallet", systemImage: "creditcard")
                }
                .tag(0)
            
            PlacesTabView()
                .tabItem {
                    Label("Places", systemImage: "map")
                }
                .tag(1)
            
            RewardsTabView()
                .tabItem {
                    Label("Rewards", systemImage: "star.circle")
                }
                .tag(2)
            
            InsightsTabView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb")
                }
                .tag(3)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

