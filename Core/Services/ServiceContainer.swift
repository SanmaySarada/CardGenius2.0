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
    
    let locationManager = LocationManager()
    
    init(
        cardService: CardServiceProtocol? = nil,
        institutionService: InstitutionServiceProtocol? = nil,
        rewardsService: RewardsServiceProtocol? = nil,
        merchantService: MerchantServiceProtocol? = nil,
        recommendationService: RecommendationServiceProtocol? = nil
    ) {
        // Use provided services or default to mocks/real implementations
        let cardService = cardService ?? MockCardService()
        self.cardService = cardService
        self.institutionService = institutionService ?? MockInstitutionService()
        self.rewardsService = rewardsService ?? MockRewardsService()
        
        // Use real MerchantService if not provided
        if let merchantService = merchantService {
            self.merchantService = merchantService
        } else {
            self.merchantService = MerchantService(locationManager: locationManager, cardService: cardService)
        }
        
        self.recommendationService = recommendationService ?? MockRecommendationService()
        
        // Start location updates
        locationManager.startUpdatingLocation()
    }
}

