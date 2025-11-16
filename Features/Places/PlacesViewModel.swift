//
//  PlacesViewModel.swift
//  CardGenius
//
//  Places View Model
//

import Foundation

@MainActor
class PlacesViewModel: ObservableObject {
    @Published var currentMerchant: Merchant?
    @Published var nearbyMerchants: [Merchant] = []
    @Published var recommendedCard: Card?
    @Published var alternativeCard: Card?
    
    var merchantService: MerchantServiceProtocol
    var cardService: CardServiceProtocol
    
    init(
        merchantService: MerchantServiceProtocol,
        cardService: CardServiceProtocol
    ) {
        self.merchantService = merchantService
        self.cardService = cardService
    }
    
    func loadCurrentMerchant() async {
        do {
            currentMerchant = try await merchantService.getCurrentMerchant()
            if let merchant = currentMerchant {
                recommendedCard = try await merchantService.getRecommendedCard(for: merchant)
                // Get alternative card (second best)
                await loadAlternativeCard(for: merchant)
            }
        } catch {
            print("Error loading current merchant: \(error)")
        }
    }
    
    func loadNearbyMerchants() async {
        do {
            nearbyMerchants = try await merchantService.getNearbyMerchants()
        } catch {
            print("Error loading nearby merchants: \(error)")
        }
    }
    
    func selectMerchant(_ merchant: Merchant) {
        currentMerchant = merchant
        Task {
            do {
                recommendedCard = try await merchantService.getRecommendedCard(for: merchant)
                await loadAlternativeCard(for: merchant)
            } catch {
                print("Error loading recommendation: \(error)")
            }
        }
    }
    
    private func loadAlternativeCard(for merchant: Merchant) async {
        do {
            let cards = try await cardService.fetchCards()
            // Simple logic: get second card with matching category
            let matchingCards = cards.filter { card in
                card.rewardCategories.contains { category in
                    category.name.lowercased() == merchant.category.rawValue.lowercased()
                }
            }
            alternativeCard = matchingCards.count > 1 ? matchingCards[1] : cards.first
        } catch {
            alternativeCard = nil
        }
    }
}

