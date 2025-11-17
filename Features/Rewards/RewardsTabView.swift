//
//  RewardsTabView.swift
//  CardGenius
//
//  Rewards Tab
//

import SwiftUI
import UIKit
import Charts

struct RewardsTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: RewardsViewModel
    @State private var isLoading: Bool = true
    
    init() {
        _viewModel = StateObject(wrappedValue: RewardsViewModel(
            rewardsService: MockRewardsService()
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cgBackground.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if let summary = viewModel.rewardsSummary {
                    ScrollView {
                        VStack(spacing: Spacing.l) {
                            // Summary Card
                            SummaryCard(summary: summary)
                                .padding(.horizontal, Spacing.l)
                                .padding(.top, Spacing.m)
                            
                            // Monthly Chart
                            MonthlyChartView(monthlyData: summary.monthlyBreakdown)
                                .padding(.horizontal, Spacing.l)
                            
                            // Category Breakdown
                            CategoryBreakdownView(categories: summary.categoryBreakdown)
                                .padding(.horizontal, Spacing.l)
                            
                            // Card Contributions
                            CardContributionsView(contributions: summary.cardContributions)
                                .padding(.horizontal, Spacing.l)
                            
                            // Optimizations Feed
                            OptimizationsFeedView(optimizations: summary.optimizations)
                                .padding(.horizontal, Spacing.l)
                                .padding(.bottom, Spacing.l)
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .onAppear {
                viewModel.rewardsService = serviceContainer.rewardsService
            }
            .task {
                await viewModel.loadRewardsSummary()
                isLoading = false
            }
        }
    }
}

struct SummaryCard: View {
    let summary: RewardsSummary
    @State private var animateGradient = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("This month you've earned")
                .font(.cgBody(15))
                .foregroundColor(.cgSecondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Text("\(summary.currentMonthPoints)")
                    .font(.cgTitle(48))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.cgAccentGradientStart,
                                Color.cgAccentGradientEnd
                            ],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                Text("points")
                    .font(.cgHeadline(22))
                    .foregroundColor(.cgSecondaryText)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: Spacing.m) {
                Text("≈ \(formatCurrency(summary.currentMonthValue))")
                    .font(.cgHeadline(18))
                    .fontWeight(.semibold)
                    .foregroundColor(.cgPrimaryText)
                
                if summary.percentageChange > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("\(Int(summary.percentageChange))% vs last month")
                            .font(.cgCaption(12))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.cgSuccess)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Radius.pill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .strokeBorder(Color.cgSuccess.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .cgSuccess.opacity(0.2), radius: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .liquidGlassCard(cornerRadius: Radius.xlarge)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct MonthlyChartView: View {
    let monthlyData: [MonthlyReward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Last 6 Months")
                    .font(.cgHeadline(20))
                    .fontWeight(.bold)
                    .foregroundColor(.cgPrimaryText)
            }
            
            Chart {
                ForEach(monthlyData) { month in
                    BarMark(
                        x: .value("Month", month.month),
                        y: .value("Points", month.points)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8)
                }
            }
            .frame(height: 220)
            .chartPlotStyle { plotContent in
                plotContent
                    .background(.ultraThinMaterial.opacity(0.3))
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Radius.xlarge)
    }
}

struct CategoryBreakdownView: View {
    let categories: [CategoryReward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cgGradientStart, Color.cgGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("By Category")
                    .font(.cgHeadline(20))
                    .fontWeight(.bold)
                    .foregroundColor(.cgPrimaryText)
            }
            
            ForEach(categories) { category in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Text(category.category)
                            .font(.cgHeadline(16))
                            .fontWeight(.semibold)
                            .foregroundColor(.cgPrimaryText)
                        Spacer()
                        Text("\(category.points) pts")
                            .font(.cgBody(15))
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(category.percentage / 100), height: 10)
                                .shadow(color: Color.cgAccent.opacity(0.4), radius: 4)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.vertical, Spacing.s)
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Radius.xlarge)
    }
}

struct CardContributionsView: View {
    let contributions: [CardRewardContribution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cgGradientStart, Color.cgGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Per-Card Contribution")
                    .font(.cgHeadline(20))
                    .fontWeight(.bold)
                    .foregroundColor(.cgPrimaryText)
            }
            
            ForEach(contributions) { contribution in
                HStack(spacing: Spacing.m) {
                    // Card Image or generic icon
                    if let imageName = contribution.imageName, !imageName.isEmpty,
                       let uiImage = UIImage(named: "card_images/\(imageName)") ?? UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 36)
                            .cornerRadius(Radius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.small)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    } else {
                        // Fallback generic icon
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.small)
                                .fill(.ultraThinMaterial)
                                .frame(width: 56, height: 36)
                            
                            RoundedRectangle(cornerRadius: Radius.small)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cgPrimary.opacity(0.3), Color.cgPrimary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 36)
                            
                            Image(systemName: "creditcard.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cgPrimary, Color.cgAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color.cgPrimary.opacity(0.2), radius: 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contribution.cardName)
                            .font(.cgHeadline(16))
                            .fontWeight(.semibold)
                            .foregroundColor(.cgPrimaryText)
                        
                        if let tagline = contribution.tagline {
                            Text(tagline)
                                .font(.cgCaption(12))
                                .foregroundColor(.cgSecondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(contribution.points)")
                        .font(.cgHeadline(18))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    + Text(" pts")
                        .font(.cgCaption(12))
                        .fontWeight(.medium)
                        .foregroundColor(.cgSecondaryText)
                }
                .padding(Spacing.m)
                .background(.ultraThinMaterial)
                .cornerRadius(Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.medium)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Radius.xlarge)
    }
}

struct OptimizationsFeedView: View {
    let optimizations: [OptimizationWin]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .yellow.opacity(0.3), radius: 8)
                
                Text("CardGenius Wins")
                    .font(.cgHeadline(20))
                    .fontWeight(.bold)
                    .foregroundColor(.cgPrimaryText)
            }
            
            ForEach(optimizations) { optimization in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(alignment: .top, spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(optimization.title)
                                .font(.cgHeadline(16))
                                .fontWeight(.semibold)
                                .foregroundColor(.cgPrimaryText)
                            
                            Text(optimization.description)
                                .font(.cgBody(14))
                                .foregroundColor(.cgSecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption2)
                            Text("\(optimization.pointsEarned) points")
                                .font(.cgCaption(12))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.cgSuccess)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Radius.pill)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .strokeBorder(Color.cgSuccess.opacity(0.3), lineWidth: 0.5)
                        )
                        
                        Spacer()
                        
                        Text(formatDate(optimization.date))
                            .font(.cgCaption(11))
                            .foregroundColor(.cgTertiaryText)
                    }
                }
                .padding(Spacing.m)
                .background(.ultraThinMaterial)
                .cornerRadius(Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.medium)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: Radius.xlarge)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


