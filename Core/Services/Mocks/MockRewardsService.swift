//
//  MockRewardsService.swift
//  CardGenius
//
//  Mock Rewards Service Implementation
//

import Foundation

class MockRewardsService: RewardsServiceProtocol {
    private let cardService = MockCardService()
    
    func fetchRewardsSummary() async throws -> RewardsSummary {
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Get actual wallet cards
        let cards = try await cardService.fetchCards()
        
        // Generate card contributions from actual cards with random points
        let cardContributions = cards.enumerated().map { index, card in
            let points: Int
            let tagline: String
            
            // Assign realistic points (higher for first cards, lower for later ones)
            switch index {
            case 0:
                points = Int.random(in: 4500...6000)
                tagline = card.rewardCategories.first?.name ?? "Most used"
            case 1:
                points = Int.random(in: 3000...4500)
                tagline = card.rewardCategories.first?.name ?? "Travel & Dining"
            case 2:
                points = Int.random(in: 2000...3000)
                tagline = card.rewardCategories.first?.name ?? "Everyday Shopping"
            default:
                points = Int.random(in: 500...2000)
                tagline = card.rewardCategories.first?.name ?? "General Purpose"
            }
            
            return CardRewardContribution(
                id: "contrib-\(card.id)",
                cardId: card.id,
                cardName: card.displayName,
                points: points,
                tagline: tagline,
                imageName: card.imageName
            )
        }
        
        // Keep the rest of the summary data
        var summary = MockData.sampleRewardsSummary
        summary = RewardsSummary(
            currentMonthPoints: summary.currentMonthPoints,
            currentMonthValue: summary.currentMonthValue,
            previousMonthPoints: summary.previousMonthPoints,
            monthlyBreakdown: summary.monthlyBreakdown,
            categoryBreakdown: summary.categoryBreakdown,
            cardContributions: cardContributions,
            optimizations: summary.optimizations
        )
        
        return summary
    }
}

