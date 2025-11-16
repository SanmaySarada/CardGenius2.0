//
//  Recommendation.swift
//  CardGenius
//
//  Card Recommendation Model
//

import Foundation

struct CardRecommendation: Identifiable, Codable {
    let id: String
    let issuer: String
    let cardName: String
    let logoAssetName: String?
    let categoryFocus: [String] // e.g., ["Groceries", "Online Shopping"]
    let estimatedYearlyBenefit: Double
    let explanation: String
    let tags: [RecommendationTag]
    let signUpBonus: String?
    let aprRange: String?
    let whyWeRecommend: [String]
    var isDismissed: Bool
    
    enum RecommendationTag: String, Codable {
        case preApprovalLikely = "Pre-approval likely"
        case beginnerFriendly = "Beginner friendly"
        case highRewards = "High rewards"
        case noAnnualFee = "No annual fee"
        case travelFocused = "Travel focused"
    }
}

