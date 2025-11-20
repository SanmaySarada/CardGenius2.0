//
//  ServiceContainer.swift
//  CardGenius
//
//  Service Container for Dependency Injection
//

import Foundation

class ServiceContainer: ObservableObject {
    let cardService: CardServiceProtocol
    let institutionService: InstitutionServiceProtocol
    let rewardsService: RewardsServiceProtocol
    let merchantService: MerchantServiceProtocol
    let recommendationService: RecommendationServiceProtocol
    
    init(
        cardService: CardServiceProtocol? = nil,
        institutionService: InstitutionServiceProtocol? = nil,
        rewardsService: RewardsServiceProtocol? = nil,
        merchantService: MerchantServiceProtocol? = nil,
        recommendationService: RecommendationServiceProtocol? = nil
    ) {
        // Use provided services or default to mocks
        self.cardService = cardService ?? MockCardService()
        self.institutionService = institutionService ?? MockInstitutionService()
        self.rewardsService = rewardsService ?? MockRewardsService()
        self.merchantService = merchantService ?? MockMerchantService()
        self.recommendationService = recommendationService ?? MockRecommendationService()
    }
}

