//
//  MockRecommendationService.swift
//  CardGenius
//
//  Mock Recommendation Service Implementation
//

import Foundation

class MockRecommendationService: RecommendationServiceProtocol {
    private var recommendations: [CardRecommendation] = []
    
    init() {
        recommendations = MockData.sampleRecommendations
    }
    
    func fetchCardRecommendations() async throws -> [CardRecommendation] {
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        return recommendations.filter { !$0.isDismissed }
    }
    
    func dismissRecommendation(_ recommendation: CardRecommendation) async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            recommendations[index].isDismissed = true
        }
    }
    
    func getEstimatedYearlyGain() async throws -> Double {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return 320.0 // Mock value
    }
}

