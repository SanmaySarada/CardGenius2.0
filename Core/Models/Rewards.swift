//
//  Rewards.swift
//  CardGenius
//
//  Rewards Models
//

import Foundation

struct RewardsSummary: Codable {
    let currentMonthPoints: Int
    let currentMonthValue: Double
    let previousMonthPoints: Int
    let monthlyBreakdown: [MonthlyReward]
    let categoryBreakdown: [CategoryReward]
    let cardContributions: [CardRewardContribution]
    let optimizations: [OptimizationWin]
    
    var percentageChange: Double {
        guard previousMonthPoints > 0 else { return 0 }
        return Double(currentMonthPoints - previousMonthPoints) / Double(previousMonthPoints) * 100
    }
}

struct MonthlyReward: Identifiable, Codable {
    let id: String
    let month: String // e.g., "Jan 2024"
    let points: Int
    let value: Double
}

struct CategoryReward: Identifiable, Codable {
    let id: String
    let category: String
    let points: Int
    let percentage: Double
}

struct CardRewardContribution: Identifiable, Codable {
    let id: String
    let cardId: String
    let cardName: String
    let points: Int
    let tagline: String? // e.g., "Most used at Restaurants"
    let imageName: String? // Card image from card_images folder
}

struct OptimizationWin: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let pointsEarned: Int
    let date: Date
}

