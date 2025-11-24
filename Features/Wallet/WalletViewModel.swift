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
    let cardImageName: String?
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
        print("[WalletViewModel] Loading current suggestion...")
        
        // Retry logic: try up to 5 times with delays to wait for actual location
        // STRICT: Only retries to wait for actual location - NO fallback to default coordinates
        var retries = 0
        let maxRetries = 5
        
        while retries < maxRetries {
            do {
                guard let merchant = try await merchantService.getCurrentMerchant() else {
                    print("[WalletViewModel] No merchant found (waiting for actual location), retry \(retries + 1)/\(maxRetries)")
                    if retries < maxRetries - 1 {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        retries += 1
                        continue
                    }
                    // Explicitly set to nil - no fallback to mock/default coordinates
                    print("[WalletViewModel] Failed to get merchant - requires actual location coordinates")
                    currentSuggestion = nil
                    return
                }
                
                // VALIDATION: Confirm merchant came from actual location
                // MerchantService.getCurrentMerchant() only returns merchants from actual location
                // Log the location coordinates used for this suggestion
                print("[WalletViewModel] Merchant '\(merchant.name)' obtained from actual location: \(merchant.location.latitude), \(merchant.location.longitude)")
                print("[WalletViewModel] Merchant category: \(merchant.category.rawValue), types: \(merchant.rawTypes ?? [])")
                
                guard let recommendedCard = try await merchantService.getRecommendedCard(for: merchant) else {
                    print("[WalletViewModel] No card recommendation found for merchant at location: \(merchant.location.latitude), \(merchant.location.longitude)")
                    currentSuggestion = nil
                    return
                }
                
                let topCategory = recommendedCard.rewardCategories.first
                let rewardText = topCategory?.description ?? "rewards"
                
                print("[WalletViewModel] Successfully loaded suggestion based on actual location:")
                print("[WalletViewModel]   - Location: \(merchant.location.latitude), \(merchant.location.longitude)")
                print("[WalletViewModel]   - Merchant: \(merchant.name)")
                print("[WalletViewModel]   - Recommended Card: \(recommendedCard.displayName)")
                print("[WalletViewModel]   - Reward: \(rewardText)")
                
                currentSuggestion = CardSuggestion(
                    cardId: recommendedCard.id,
                    cardName: recommendedCard.displayName,
                    merchantName: merchant.name,
                    rewardText: rewardText,
                    cardImageName: recommendedCard.imageName
                )
                return // Success, exit retry loop
            } catch {
                print("[WalletViewModel] Error loading suggestion (attempt \(retries + 1)/\(maxRetries)): \(error.localizedDescription)")
                if retries < maxRetries - 1 {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    retries += 1
                } else {
                    print("[WalletViewModel] Clearing suggestion due to error - requires actual location")
                    currentSuggestion = nil
                    return
                }
            }
        }
        
        print("[WalletViewModel] Failed to load suggestion after \(maxRetries) attempts - clearing suggestion")
        currentSuggestion = nil
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
    
    func moveCardToTop(_ cardId: String) {
        guard let index = cards.firstIndex(where: { $0.id == cardId }),
              index > 0 else { return }
        
        let card = cards.remove(at: index)
        cards.insert(card, at: 0)
    }
}

