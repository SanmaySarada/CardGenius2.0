//
//  InsightsTabView.swift
//  CardGenius
//
//  Insights / Recommendations Tab
//

import SwiftUI

struct InsightsTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: InsightsViewModel
    @State private var selectedRecommendation: CardRecommendation?
    @State private var showingDetail: Bool = false
    @State private var estimatedGain: Double = 0
    
    init() {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(
            recommendationService: MockRecommendationService()
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cgBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.l) {
                        // Intro Block
                        IntroBlock(estimatedGain: estimatedGain)
                            .padding(.horizontal, Spacing.l)
                            .padding(.top, Spacing.m)
                        
                        // Recommendations
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(Spacing.xxl)
                        } else {
                            ForEach(viewModel.recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation) {
                                    selectedRecommendation = recommendation
                                    showingDetail = true
                                }
                                .padding(.horizontal, Spacing.l)
                            }
                        }
                    }
                    .padding(.bottom, Spacing.l)
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showingDetail) {
                if let recommendation = selectedRecommendation {
                    RecommendationDetailView(
                        recommendation: recommendation,
                        onDismiss: {
                            Task {
                                await viewModel.dismissRecommendation(recommendation)
                            }
                        }
                    )
                }
            }
            .onAppear {
                viewModel.recommendationService = serviceContainer.recommendationService
            }
            .task {
                await viewModel.loadRecommendations()
                estimatedGain = await viewModel.getEstimatedGain()
            }
        }
    }
}

struct IntroBlock: View {
    let estimatedGain: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Based on your spending, you could earn more with these cards.")
                .font(.cgBody(17))
                .foregroundColor(.cgPrimaryText)
            
            HStack(spacing: Spacing.s) {
                Text("You could earn")
                    .font(.cgBody(15))
                    .foregroundColor(.cgSecondaryText)
                Text("≈ \(formatCurrency(estimatedGain))")
                    .font(.cgHeadline(20))
                    .foregroundColor(.cgAccent)
                Text("more per year")
                    .font(.cgBody(15))
                    .foregroundColor(.cgSecondaryText)
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

struct RecommendationCard: View {
    let recommendation: CardRecommendation
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // Header
            HStack(spacing: Spacing.m) {
                RoundedRectangle(cornerRadius: Radius.small)
                    .fill(Color.cgTertiaryBackground)
                    .frame(width: 50, height: 35)
                    .overlay(
                        Text(String(recommendation.issuer.prefix(1)))
                            .font(.cgHeadline(18))
                            .foregroundColor(.cgSecondaryText)
                    )
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(recommendation.cardName)
                        .font(.cgHeadline(17))
                        .foregroundColor(.cgPrimaryText)
                    
                    Text(recommendation.issuer)
                        .font(.cgBody(13))
                        .foregroundColor(.cgSecondaryText)
                }
            }
            
            // Category Focus
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(recommendation.categoryFocus, id: \.self) { category in
                        Text(category)
                            .font(.cgCaption(11))
                            .foregroundColor(.cgPrimary)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.cgPrimary.opacity(0.1))
                            .cornerRadius(Radius.pill)
                    }
                }
            }
            
            // Benefit
            HStack {
                Text("Potential benefit:")
                    .font(.cgBody(13))
                    .foregroundColor(.cgSecondaryText)
                Text("~ \(formatCurrency(recommendation.estimatedYearlyBenefit))/year")
                    .font(.cgHeadline(15))
                    .foregroundColor(.cgAccent)
            }
            
            // Explanation
            Text(recommendation.explanation)
                .font(.cgBody(13))
                .foregroundColor(.cgSecondaryText)
                .lineLimit(2)
            
            // Tags
            HStack(spacing: Spacing.s) {
                ForEach(recommendation.tags, id: \.rawValue) { tag in
                    Text(tag.rawValue)
                        .font(.cgCaption(10))
                        .foregroundColor(.cgPrimary)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 4)
                        .background(Color.cgPrimary.opacity(0.1))
                        .cornerRadius(Radius.pill)
                }
            }
            
            // Actions
            HStack(spacing: Spacing.m) {
                Button(action: onTap) {
                    Text("Quick Apply")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: {}) {
                    Text("Compare")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
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

struct RecommendationDetailView: View {
    let recommendation: CardRecommendation
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var hasThisCard: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    // Card Hero
                    RoundedRectangle(cornerRadius: Radius.large)
                        .fill(
                            LinearGradient(
                                colors: [Color.cgPrimary, Color.cgAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Text(recommendation.cardName)
                                    .font(.cgTitle(28))
                                    .foregroundColor(.white)
                                Text(recommendation.issuer)
                                    .font(.cgBody(15))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        )
                        .padding(.horizontal, Spacing.l)
                    
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        // Sign-up Bonus
                        if let signUpBonus = recommendation.signUpBonus {
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                Text("Sign-up Bonus")
                                    .font(.cgHeadline(17))
                                    .foregroundColor(.cgPrimaryText)
                                Text(signUpBonus)
                                    .font(.cgBody(15))
                                    .foregroundColor(.cgSecondaryText)
                            }
                            .padding(Spacing.m)
                            .background(Color.cgSecondaryBackground)
                            .cornerRadius(Radius.medium)
                        }
                        
                        // APR
                        if let aprRange = recommendation.aprRange {
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                Text("APR")
                                    .font(.cgHeadline(17))
                                    .foregroundColor(.cgPrimaryText)
                                Text(aprRange)
                                    .font(.cgBody(13))
                                    .foregroundColor(.cgSecondaryText)
                            }
                            .padding(Spacing.m)
                            .background(Color.cgSecondaryBackground)
                            .cornerRadius(Radius.medium)
                        }
                        
                        // Why We Recommend
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            Text("Why we recommend this")
                                .font(.cgHeadline(17))
                                .foregroundColor(.cgPrimaryText)
                            
                            ForEach(recommendation.whyWeRecommend, id: \.self) { reason in
                                HStack(alignment: .top, spacing: Spacing.s) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cgSuccess)
                                        .font(.caption)
                                    Text(reason)
                                        .font(.cgBody(15))
                                        .foregroundColor(.cgSecondaryText)
                                }
                            }
                        }
                        .padding(Spacing.m)
                        .background(Color.cgSecondaryBackground)
                        .cornerRadius(Radius.medium)
                        
                        // Toggle
                        Toggle("I already have this card", isOn: $hasThisCard)
                            .font(.cgBody(15))
                            .padding(Spacing.m)
                            .background(Color.cgSecondaryBackground)
                            .cornerRadius(Radius.medium)
                            .onChange(of: hasThisCard) { newValue in
                                if newValue {
                                    onDismiss()
                                    dismiss()
                                }
                            }
                        
                        // Apply Button
                        Button(action: {}) {
                            Text("Apply Now")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, Spacing.m)
                    }
                    .padding(Spacing.l)
                }
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

