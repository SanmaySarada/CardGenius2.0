//
//  WalletTabView.swift
//  CardGenius
//
//  Wallet Tab - Main Card Stack View
//

import SwiftUI
import UIKit

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
                .zIndex(0)
                
                if viewModel.isLoading {
                    VStack(spacing: Spacing.l) {
                        ForEach(0..<3) { _ in
                            CardSkeletonView()
                        }
                    }
                    .padding()
                    .zIndex(1)
                } else if viewModel.cards.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "No cards yet",
                        message: "Let's add some cards to get started",
                        actionTitle: "Add Card",
                        action: { showingAddCard = true }
                    )
                    .zIndex(1)
                } else {
                    // Main content
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
                            
                            // Card Stack (z-index handled internally)
                            CardStackView(
                                cards: $viewModel.cards,
                                onCardTap: { card in
                                    selectedCard = card
                                    showingCardDetail = true
                                }
                            )
                            .padding(.vertical, Spacing.l)
                        }
                    }
                    .zIndex(1)
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
                // Card Image or fallback icon
                if let imageName = suggestion.cardImageName, !imageName.isEmpty,
                   let uiImage = UIImage(named: "card_images/\(imageName)") ?? UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 36)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.cgAccentGradientStart.opacity(0.6),
                                            Color.cgAccentGradientEnd.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.cgAccent.opacity(0.4), radius: 12)
                } else {
                    // Fallback to sparkles icon
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
                }
                
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
    @Binding var cards: [Card]
    let onCardTap: (Card) -> Void
    
    @State private var lastTopCardMovedTime: Date? = nil
    
    private let cardHeight: CGFloat = 220
    private let cardSpacing: CGFloat = 25
    private let cardOverlap: CGFloat = 140
    private let tapCooldown: TimeInterval = 1.0 // 1 second cooldown
    
    var body: some View {
        VStack(spacing: -cardOverlap) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isTopCard = index == 0
                    
                    CardView(
                        card: card,
                        isTopCard: isTopCard,
                        offset: CGFloat(index) * cardSpacing,
                        scale: max(0.88, 1.0 - CGFloat(index) * 0.08)
                    )
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, CGFloat(index) * cardSpacing)
                    .zIndex(Double(cards.count - index))
                    .onTapGesture {
                        // Check if this card is already at the top
                        if index == 0 {
                            // Card is at the top - check cooldown before opening
                            let now = Date()
                            if let lastMoved = lastTopCardMovedTime {
                                let timeSinceMove = now.timeIntervalSince(lastMoved)
                                if timeSinceMove >= tapCooldown {
                                    // Cooldown has passed - open card detail
                                    onCardTap(card)
                                }
                            } else {
                                // No recent move - open card detail
                                onCardTap(card)
                            }
                        } else {
                            // Card is not at top - move it to top
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                if let tappedIndex = cards.firstIndex(where: { $0.id == card.id }) {
                                    let tappedCard = cards.remove(at: tappedIndex)
                                    cards.insert(tappedCard, at: 0)
                                    // Record the time when card moved to top
                                    lastTopCardMovedTime = Date()
                                }
                            }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press opens card detail view
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onCardTap(card)
                        }
                    }
                }
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl + cardHeight) // Extra padding to see bottom of last card
    }
}

