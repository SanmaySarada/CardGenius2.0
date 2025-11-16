//
//  InsightsViewModel.swift
//  CardGenius
//
//  Insights View Model
//

import Foundation

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var recommendations: [CardRecommendation] = []
    @Published var isLoading: Bool = false
    
    var recommendationService: RecommendationServiceProtocol
    
    init(recommendationService: RecommendationServiceProtocol) {
        self.recommendationService = recommendationService
    }
    
    func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            recommendations = try await recommendationService.fetchCardRecommendations()
        } catch {
            print("Error loading recommendations: \(error)")
        }
    }
    
    func dismissRecommendation(_ recommendation: CardRecommendation) async {
        do {
            try await recommendationService.dismissRecommendation(recommendation)
            await loadRecommendations()
        } catch {
            print("Error dismissing recommendation: \(error)")
        }
    }
    
    func getEstimatedGain() async -> Double {
        do {
            return try await recommendationService.getEstimatedYearlyGain()
        } catch {
            return 0.0
        }
    }
}

