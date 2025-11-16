//
//  RewardsTabView.swift
//  CardGenius
//
//  Rewards Tab
//

import SwiftUI
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("This month you've earned")
                .font(.cgBody(15))
                .foregroundColor(.cgSecondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Text("\(summary.currentMonthPoints)")
                    .font(.cgTitle(42))
                    .foregroundColor(.cgPrimaryText)
                Text("points")
                    .font(.cgHeadline(20))
                    .foregroundColor(.cgSecondaryText)
            }
            
            HStack(spacing: Spacing.s) {
                Text("≈ \(formatCurrency(summary.currentMonthValue))")
                    .font(.cgHeadline(17))
                    .foregroundColor(.cgPrimaryText)
                
                if summary.percentageChange > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text("\(Int(summary.percentageChange))% vs last month")
                            .font(.cgCaption(12))
                    }
                    .foregroundColor(.cgSuccess)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.large)
        .cgCardShadow()
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
            Text("Last 6 Months")
                .font(.cgHeadline(20))
                .foregroundColor(.cgPrimaryText)
            
            Chart {
                ForEach(monthlyData) { month in
                    BarMark(
                        x: .value("Month", month.month),
                        y: .value("Points", month.points)
                    )
                    .foregroundStyle(Color.cgAccent.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
        }
        .padding(Spacing.l)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.large)
        .cgCardShadow()
    }
}

struct CategoryBreakdownView: View {
    let categories: [CategoryReward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("By Category")
                .font(.cgHeadline(20))
                .foregroundColor(.cgPrimaryText)
            
            ForEach(categories) { category in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(category.category)
                            .font(.cgHeadline(15))
                            .foregroundColor(.cgPrimaryText)
                        Spacer()
                        Text("\(category.points) pts")
                            .font(.cgBody(15))
                            .foregroundColor(.cgSecondaryText)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cgTertiaryBackground)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cgAccent)
                                .frame(width: geometry.size.width * CGFloat(category.percentage / 100), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .padding(Spacing.l)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.large)
        .cgCardShadow()
    }
}

struct CardContributionsView: View {
    let contributions: [CardRewardContribution]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Per-Card Contribution")
                .font(.cgHeadline(20))
                .foregroundColor(.cgPrimaryText)
            
            ForEach(contributions) { contribution in
                HStack(spacing: Spacing.m) {
                    RoundedRectangle(cornerRadius: Radius.small)
                        .fill(Color.cgPrimary.opacity(0.2))
                        .frame(width: 40, height: 30)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .font(.caption)
                                .foregroundColor(.cgPrimary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contribution.cardName)
                            .font(.cgHeadline(15))
                            .foregroundColor(.cgPrimaryText)
                        
                        if let tagline = contribution.tagline {
                            Text(tagline)
                                .font(.cgCaption(12))
                                .foregroundColor(.cgSecondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(contribution.points) pts")
                        .font(.cgHeadline(15))
                        .foregroundColor(.cgAccent)
                }
                .padding(Spacing.m)
                .background(Color.cgSecondaryBackground)
                .cornerRadius(Radius.medium)
            }
        }
        .padding(Spacing.l)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.large)
        .cgCardShadow()
    }
}

struct OptimizationsFeedView: View {
    let optimizations: [OptimizationWin]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("CardGenius Wins")
                .font(.cgHeadline(20))
                .foregroundColor(.cgPrimaryText)
            
            ForEach(optimizations) { optimization in
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cgAccent)
                        Text(optimization.title)
                            .font(.cgHeadline(15))
                            .foregroundColor(.cgPrimaryText)
                    }
                    
                    Text(optimization.description)
                        .font(.cgBody(13))
                        .foregroundColor(.cgSecondaryText)
                    
                    HStack {
                        Text("+\(optimization.pointsEarned) points")
                            .font(.cgCaption(12))
                            .foregroundColor(.cgSuccess)
                        Spacer()
                        Text(formatDate(optimization.date))
                            .font(.cgCaption(12))
                            .foregroundColor(.cgTertiaryText)
                    }
                }
                .padding(Spacing.m)
                .background(Color.cgSecondaryBackground)
                .cornerRadius(Radius.medium)
            }
        }
        .padding(Spacing.l)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.large)
        .cgCardShadow()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

