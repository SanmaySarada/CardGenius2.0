//
//  MockMerchantService.swift
//  CardGenius
//
//  Mock Merchant Service Implementation
//

import Foundation

class MockMerchantService: MerchantServiceProtocol {
    private var currentMerchant: Merchant? = MockData.sampleCurrentMerchant
    
    func getCurrentMerchant() async throws -> Merchant? {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        return currentMerchant
    }
    
    func getNearbyMerchants() async throws -> [Merchant] {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return MockData.sampleNearbyMerchants
    }
    
    func getRecommendedCard(for merchant: Merchant) async throws -> Card? {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Simple mock logic: return first card with matching category
        let cards = MockData.sampleCards
        return cards.first { card in
            card.rewardCategories.contains { category in
                category.name.lowercased() == merchant.category.rawValue.lowercased()
            }
        } ?? cards.first
    }
}

