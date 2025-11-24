//
//  DashboardTabView.swift
//  CardGenius
//
//  Rocket Money inspired dashboard composed of placeholder content.
//

import SwiftUI

struct DashboardTabView: View {
    @State private var isLoadingSummary = true
    @State private var isLoadingAccounts = true
    @State private var isLoadingTransactions = true
    @State private var isLoadingLocationSuggestion = true
    
    @State private var dashboardSummary: DashboardSummaryPlaceholder?
    @State private var accountsSummary: [AccountSummaryPlaceholder] = []
    @State private var transactions: [TransactionPlaceholder] = []
    @State private var locationSuggestion: LocationSuggestionPlaceholder?
    
    private let accountRows: [AccountRow] = [
        .init(title: "Checking", icon: "house", tint: .cgPrimary),
        .init(title: "Credit Cards", icon: "creditcard", tint: .cgAccent),
        .init(title: "Net Cash", icon: "dollarsign.circle", tint: .green),
        .init(title: "Savings", icon: "lock.circle", tint: .orange),
        .init(title: "Investments", icon: "chart.line.uptrend.xyaxis", tint: .purple)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    locationBanner
                    heroCard
                    accountsPanel
                    transactionsPanel
                }
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .task {
                await loadDashboardSummary()
                await loadAccounts()
                await loadTransactions()
                await loadLocationSuggestion()
            }
        }
    }
    
    private var locationBanner: some View {
        DashboardLocationBanner(
            suggestion: locationSuggestion ?? .placeholder,
            isLoading: isLoadingLocationSuggestion
        )
    }
    
    private var heroCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("You've saved")
                            .font(.cgSubheadline(15))
                            .foregroundColor(.cgSecondaryText)
                        
                        if let summary = dashboardSummary, !isLoadingSummary {
                            Text(summary.primaryDisplay)
                                .font(.cgTitle(46))
                                .foregroundColor(.green)
                                .shadow(color: Color.green.opacity(0.25), radius: 8, x: 0, y: 4)
                        } else {
                            SkeletonBar(width: 180, height: 44, cornerRadius: 10)
                                .foregroundColor(.green.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                }
                
                LineChartPlaceholder()
                
            }
        }
    }
    
    private var accountsPanel: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack {
                    Text("Accounts")
                        .font(.cgHeadline(20, weight: .bold))
                    Spacer()
                    HStack(spacing: Spacing.s) {
                        Text("Updated moments ago")
                            .font(.cgCaption(12))
                            .foregroundColor(.cgSecondaryText)
                        Text("Sync now")
                            .font(.cgCaption(12))
                            .foregroundColor(.cgAccent)
                    }
                }
                
                VStack(spacing: Spacing.s) {
                    ForEach(accountRows) { row in
                        HStack(spacing: Spacing.m) {
                            Circle()
                                .fill(row.tint.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: row.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(row.tint)
                                )
                            
                            Text(row.title)
                                .font(.cgBody(17, weight: .semibold))
                                .foregroundColor(.cgPrimaryText)
                            
                            Spacer()
                            
                            if let value = accountsSummary.first(where: { $0.accountType == row.title })?.displayValue,
                               !isLoadingAccounts {
                                Text(value)
                                    .font(.cgSubheadline(15))
                                    .foregroundColor(.cgPrimaryText)
                            } else {
                                SkeletonBar(width: 70, height: 16, cornerRadius: 8)
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                        
                        if row.id != accountRows.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var transactionsPanel: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack {
            Text("Recent transactions")
                .font(.cgHeadline(20, weight: .bold))
                    Spacer()
                    Text("See all")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgAccent)
                }
                
                HeaderRow()
                
                VStack(spacing: Spacing.s) {
                    ForEach(0..<6, id: \.self) { _ in
                        TransactionPlaceholderRow()
                    }
                }
                
                if transactions.isEmpty && !isLoadingTransactions {
                    Text("No transactions yet")
                        .font(.cgSubheadline(14))
                        .foregroundColor(.cgSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Spacing.s)
                }
            }
        }
    }
}

// MARK: - Placeholder Models

struct DashboardSummaryPlaceholder {
    let primaryDisplay: String
}

struct AccountSummaryPlaceholder: Identifiable {
    let id = UUID()
    let accountType: String
    let displayValue: String
}

struct TransactionPlaceholder: Identifiable {
    let id = UUID()
    let merchant: String
    let date: String
    let amount: String
}

struct LocationSuggestionPlaceholder {
    let merchantName: String
    let cardName: String
    let rewardText: String
    let iconSystemName: String
    
    static let placeholder = LocationSuggestionPlaceholder(
        merchantName: "BART/MUNI Ellis/Stockton Entrance",
        cardName: "Recommended",
        rewardText: "8.0% back",
        iconSystemName: "sparkles"
    )
}

struct AccountRow: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
}

// MARK: - Placeholder Networking

extension DashboardTabView {
    private func loadDashboardSummary() async {
        isLoadingSummary = true
        defer { isLoadingSummary = false }
        let endpoint = "/api/dashboard"
        _ = endpoint
        dashboardSummary = nil
    }
    
    private func loadAccounts() async {
        isLoadingAccounts = true
        defer { isLoadingAccounts = false }
        let endpoint = "/api/accounts"
        _ = endpoint
        accountsSummary = []
    }
    
    private func loadTransactions() async {
        isLoadingTransactions = true
        defer { isLoadingTransactions = false }
        let endpoint = "/api/transactions"
        _ = endpoint
        transactions = []
    }
    
    private func loadLocationSuggestion() async {
        isLoadingLocationSuggestion = true
        defer { isLoadingLocationSuggestion = false }
        let endpoint = "/api/location-suggestion"
        _ = endpoint
        locationSuggestion = LocationSuggestionPlaceholder.placeholder
    }
}

// MARK: - Reusable Views

private struct DashboardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
                .padding(Spacing.l)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: Radius.card)
    }
}

private struct SkeletonBar: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
    }
}

private struct LineChartPlaceholder: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cgAccentGradientStart.opacity(0.15),
                                Color.cgAccentGradientEnd.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 6) {
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
                .padding(.vertical, Spacing.m)
                
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height
                    path.move(to: CGPoint(x: 0, y: height * 0.75))
                    path.addCurve(
                        to: CGPoint(x: width * 0.4, y: height * 0.35),
                        control1: CGPoint(x: width * 0.15, y: height * 0.6),
                        control2: CGPoint(x: width * 0.25, y: height * 0.2)
                    )
                    path.addCurve(
                        to: CGPoint(x: width, y: height * 0.2),
                        control1: CGPoint(x: width * 0.6, y: height * 0.5),
                        control2: CGPoint(x: width * 0.8, y: height * 0.15)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .glowEffect(color: .cgAccent, radius: 12)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
                    .offset(x: geo.size.width * 0.35 - 6, y: -geo.size.height * 0.2)
                    .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 4)
            }
        }
        .frame(height: 150)
    }
}

private struct HeaderRow: View {
    var body: some View {
        HStack {
            Text("Date")
                .font(.cgCaption(12))
                .foregroundColor(.cgSecondaryText)
                .frame(width: 60, alignment: .leading)
            Text("Name")
                .font(.cgCaption(12))
                .foregroundColor(.cgSecondaryText)
            Spacer()
            Text("Amount")
                .font(.cgCaption(12))
                .foregroundColor(.cgSecondaryText)
                .frame(width: 80, alignment: .trailing)
        }
    }
}

private struct TransactionPlaceholderRow: View {
    var body: some View {
        HStack(spacing: Spacing.m) {
            SkeletonBar(width: 40, height: 14, cornerRadius: 6)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBar(width: 160, height: 16, cornerRadius: 8)
                SkeletonBar(width: 100, height: 12, cornerRadius: 6)
            }
            
            Spacer()
            
            SkeletonBar(width: 70, height: 16, cornerRadius: 8)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct DashboardLocationBanner: View {
    let suggestion: LocationSuggestionPlaceholder
    let isLoading: Bool
    @State private var animateIcon = false
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cgAccentGradientStart.opacity(0.4),
                                Color.cgAccentGradientEnd.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: suggestion.iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animateIcon ? 360 : 0))
            }
            .shadow(color: Color.yellow.opacity(0.4), radius: 10, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if isLoading {
                    SkeletonBar(width: 200, height: 16, cornerRadius: 8)
                    SkeletonBar(width: 160, height: 12, cornerRadius: 6)
                } else {
                    Text("You're at \(suggestion.merchantName)")
                        .font(.cgSubheadline(15))
                        .fontWeight(.semibold)
                        .foregroundColor(.cgPrimaryText)
                    Text("Use \(suggestion.cardName) for \(suggestion.rewardText)")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgSecondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(Spacing.m)
        .liquidGlassCard(cornerRadius: Radius.card)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                animateIcon = true
            }
        }
    }
}

#Preview("Dashboard") {
    DashboardTabView()
}

