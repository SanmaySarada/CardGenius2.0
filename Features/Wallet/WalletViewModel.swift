//
//  WalletViewModel.swift
//  CardGenius
//
//  Wallet View Model
//

import Foundation

struct CardSuggestion {
    let cardId: String
    let cardName: String
    let merchantName: String
    let rewardText: String
}

@MainActor
class WalletViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var isLoading: Bool = false
    @Published var currentSuggestion: CardSuggestion?
    
    var cardService: CardServiceProtocol
    var merchantService: MerchantServiceProtocol
    var recommendationService: RecommendationServiceProtocol
    
    init(
        cardService: CardServiceProtocol,
        merchantService: MerchantServiceProtocol,
        recommendationService: RecommendationServiceProtocol
    ) {
        self.cardService = cardService
        self.merchantService = merchantService
        self.recommendationService = recommendationService
    }
    
    func loadCards() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            cards = try await cardService.fetchCards()
        } catch {
            // Handle error
            print("Error loading cards: \(error)")
        }
    }
    
    func loadCurrentSuggestion() async {
        do {
            guard let merchant = try await merchantService.getCurrentMerchant(),
                  let recommendedCard = try await merchantService.getRecommendedCard(for: merchant) else {
                currentSuggestion = nil
                return
            }
            
            let topCategory = recommendedCard.rewardCategories.first
            let rewardText = topCategory.map { "\(Int($0.multiplier))x \($0.name)" } ?? "rewards"
            
            currentSuggestion = CardSuggestion(
                cardId: recommendedCard.id,
                cardName: recommendedCard.displayName,
                merchantName: merchant.name,
                rewardText: rewardText
            )
        } catch {
            currentSuggestion = nil
        }
    }
    
    func updateCard(_ card: Card) async {
        do {
            let updated = try await cardService.updateCard(card)
            if let index = cards.firstIndex(where: { $0.id == updated.id }) {
                cards[index] = updated
            }
        } catch {
            print("Error updating card: \(error)")
        }
    }
}

