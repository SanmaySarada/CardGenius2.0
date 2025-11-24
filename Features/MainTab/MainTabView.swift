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
        ZStack {
            // Content Views
            Group {
                switch selectedTab {
                case 0:
                    DashboardTabView()
                case 1:
                    WalletTabView()
                case 2:
                    RewardsTabView()
                case 3:
                    InsightsTabView()
                default:
                    DashboardTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Liquid Glass Tab Bar
            VStack {
                Spacer()
                LiquidGlassTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(icon: String, label: String, tag: Int)] = [
        ("chart.line.uptrend.xyaxis", "Dashboard", 0),
        ("creditcard", "Wallet", 1),
        ("star.circle.fill", "Rewards", 2),
        ("lightbulb.fill", "Insights", 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                TabBarButton(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: selectedTab == tab.tag,
                    tag: tab.tag
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab.tag
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.m)
        .padding(.bottom, 8)
        .background(
            ZStack {
                // Glass background with blur (less transparent)
                RoundedRectangle(cornerRadius: 28)
                    .fill(.regularMaterial)
                
                // Enhanced gradient overlay for more opacity
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass border with glow
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.cgAccent.opacity(0.15), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, 20)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let tag: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Animated background circle for selected state
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cgAccentGradientStart.opacity(isSelected ? 0.3 : 0),
                                    Color.cgAccentGradientEnd.opacity(isSelected ? 0.2 : 0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .opacity(isSelected ? 1.0 : 0)
                        .shadow(color: Color.cgAccent.opacity(isSelected ? 0.3 : 0), radius: 8, x: 0, y: 4)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.cgAccent, Color.cgAccentGradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.primary.opacity(0.6), Color.primary.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(width: 50, height: 50)
                
                // Label
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .cgAccent : .primary.opacity(0.6))
                    .opacity(isSelected ? 1.0 : 0.7)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

