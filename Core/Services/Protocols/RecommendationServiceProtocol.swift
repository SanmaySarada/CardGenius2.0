//
//  RecommendationServiceProtocol.swift
//  CardGenius
//
//  Recommendation Service Protocol
//

import Foundation

protocol RecommendationServiceProtocol {
    func fetchCardRecommendations() async throws -> [CardRecommendation]
    func dismissRecommendation(_ recommendation: CardRecommendation) async throws -> Void
    func getEstimatedYearlyGain() async throws -> Double
}

