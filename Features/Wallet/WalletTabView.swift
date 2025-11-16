//
//  WalletTabView.swift
//  CardGenius
//
//  Wallet Tab - Main Card Stack View
//

import SwiftUI

struct WalletTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: WalletViewModel
    @State private var selectedCard: Card?
    @State private var showingCardDetail: Bool = false
    @State private var showingAddCard: Bool = false
    @State private var showingSettings: Bool = false
    
    init() {
        // Temporary initialization, will be updated in onAppear
        _viewModel = StateObject(wrappedValue: WalletViewModel(
            cardService: MockCardService(),
            merchantService: MockMerchantService(),
            recommendationService: MockRecommendationService()
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.cgBackground,
                        Color.cgSecondaryBackground,
                        Color.cgTertiaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack(spacing: Spacing.l) {
                        ForEach(0..<3) { _ in
                            CardSkeletonView()
                        }
                    }
                    .padding()
                } else if viewModel.cards.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "No cards yet",
                        message: "Let's add some cards to get started",
                        actionTitle: "Add Card",
                        action: { showingAddCard = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.m) {
                            // Smart Suggestion Banner
                            if let suggestion = viewModel.currentSuggestion {
                                SmartSuggestionBanner(suggestion: suggestion) {
                                    // Scroll to recommended card
                                    if let card = viewModel.cards.first(where: { $0.id == suggestion.cardId }) {
                                        selectedCard = card
                                        showingCardDetail = true
                                    }
                                }
                                .padding(.horizontal, Spacing.l)
                                .padding(.top, Spacing.m)
                            }
                            
                            // Card Stack
                            CardStackView(
                                cards: viewModel.cards,
                                onCardTap: { card in
                                    selectedCard = card
                                    showingCardDetail = true
                                }
                            )
                            .padding(.vertical, Spacing.l)
                        }
                    }
                }
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Spacing.m) {
                        Button(action: { showingAddCard = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.cgPrimary)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.cgPrimary)
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.cgPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCardDetail) {
                if let card = selectedCard {
                    CardDetailView(card: card, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                // Initialize view model with services from environment
                viewModel.cardService = serviceContainer.cardService
                viewModel.merchantService = serviceContainer.merchantService
                viewModel.recommendationService = serviceContainer.recommendationService
            }
            .task {
                await viewModel.loadCards()
                await viewModel.loadCurrentSuggestion()
            }
        }
    }
}

struct SmartSuggestionBanner: View {
    let suggestion: CardSuggestion
    let onTap: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.m) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cgAccentGradientStart.opacity(0.3),
                                    Color.cgAccentGradientEnd.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .shadow(color: Color.yellow.opacity(0.4), radius: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("You're at \(suggestion.merchantName)")
                        .font(.cgSubheadline(14))
                        .fontWeight(.semibold)
                        .foregroundColor(.cgPrimaryText)
                    
                    Text("Use \(suggestion.cardName) for \(suggestion.rewardText)")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgSecondaryText)
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
            .liquidGlassCard(cornerRadius: Radius.large)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct CardStackView: View {
    let cards: [Card]
    let onCardTap: (Card) -> Void
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: -120) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(
                        card: card,
                        isTopCard: index == 0,
                        offset: CGFloat(index) * 20,
                        scale: max(0.85, 1.0 - CGFloat(index) * 0.1)
                    )
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, CGFloat(index) * 20)
                    .zIndex(Double(cards.count - index))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onCardTap(card)
                        }
                    }
                    .contextMenu {
                        Button(action: {}) {
                            Label("Set as default backup card", systemImage: "star.fill")
                        }
                        
                        Button(action: {}) {
                            Label("Hide from wallet", systemImage: "eye.slash")
                        }
                        
                        Button(action: { onCardTap(card) }) {
                            Label("View details", systemImage: "info.circle")
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.xl)
        }
    }
}

