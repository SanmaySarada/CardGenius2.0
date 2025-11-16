//
//  Card.swift
//  CardGenius
//
//  Card Model
//

import Foundation
import SwiftUI

struct Card: Identifiable, Codable, Hashable {
    let id: String
    let issuer: String
    let nickname: String?
    let last4: String
    let network: CardNetwork
    let cardType: CardType
    let cardStyle: CardStyle
    let status: CardStatus
    let rewardCategories: [RewardCategory]
    let creditLimit: Double?
    let currentBalance: Double?
    let currentMonthSpend: Double
    var isIncludedInOptimization: Bool
    var routingPriority: Double // 0.0 to 1.0
    let institutionId: String
    
    var displayName: String {
        nickname ?? issuer
    }
    
    var maskedNumber: String {
        "•••• \(last4)"
    }
}

enum CardNetwork: String, Codable, CaseIterable {
    case visa = "VISA"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    
    var iconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        }
    }
}

enum CardType: String, Codable {
    case credit = "Credit"
    case debit = "Debit"
    case charge = "Charge"
}

enum CardStatus: String, Codable {
    case active = "Active"
    case paused = "Paused"
    case expired = "Expired"
    case closed = "Closed"
    
    var color: Color {
        switch self {
        case .active: return .cgSuccess
        case .paused: return .cgWarning
        case .expired, .closed: return .cgError
        }
    }
}

enum CardStyle: String, Codable {
    case gold
    case platinum
    case black
    case blue
    case gradient
    
    var gradient: LinearGradient {
        switch self {
        case .gold:
            return LinearGradient(
                colors: [Color.cgCardGold, Color.cgCardGold.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .platinum:
            return LinearGradient(
                colors: [Color.cgCardPlatinum, Color.cgCardPlatinum.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .black:
            return LinearGradient(
                colors: [Color.cgCardBlack, Color.cgCardBlack.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color.cgCardBlue, Color.cgCardBlue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gradient:
            return LinearGradient(
                colors: [Color.cgPrimary, Color.cgAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct RewardCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let multiplier: Double // e.g., 3.0 for 3x
    let description: String?
}

