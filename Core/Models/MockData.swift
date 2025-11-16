//
//  MockData.swift
//  CardGenius
//
//  Mock Data for Development and Previews
//

import Foundation

enum MockData {
    static let sampleCards: [Card] = [
        Card(
            id: "card-1",
            issuer: "American Express Gold",
            nickname: "Travel Card",
            last4: "1234",
            network: .amex,
            cardType: .charge,
            cardStyle: .gold,
            status: .active,
            imageName: nil,
            rewardCategories: [
                RewardCategory(id: "cat-1", name: "Dining", multiplier: 4.0, description: "4x points on dining"),
                RewardCategory(id: "cat-2", name: "Travel", multiplier: 3.0, description: "3x points on travel")
            ],
            creditLimit: nil,
            currentBalance: nil,
            currentMonthSpend: 2450.00,
            isIncludedInOptimization: true,
            routingPriority: 0.9,
            institutionId: "inst-1"
        ),
        Card(
            id: "card-2",
            issuer: "Chase Sapphire Reserve",
            nickname: nil,
            last4: "5678",
            network: .visa,
            cardType: .credit,
            cardStyle: .blue,
            status: .active,
            imageName: nil,
            rewardCategories: [
                RewardCategory(id: "cat-3", name: "Travel", multiplier: 3.0, description: "3x points on travel and dining"),
                RewardCategory(id: "cat-4", name: "Dining", multiplier: 3.0, description: "3x points on dining")
            ],
            creditLimit: 25000.00,
            currentBalance: 8500.00,
            currentMonthSpend: 3200.00,
            isIncludedInOptimization: true,
            routingPriority: 0.8,
            institutionId: "inst-2"
        ),
        Card(
            id: "card-3",
            issuer: "Bank of America Customized Cash",
            nickname: "Groceries Card",
            last4: "9012",
            network: .visa,
            cardType: .credit,
            cardStyle: .gradient,
            status: .active,
            imageName: nil,
            rewardCategories: [
                RewardCategory(id: "cat-5", name: "Groceries", multiplier: 3.0, description: "3% cash back on groceries"),
                RewardCategory(id: "cat-6", name: "Gas", multiplier: 2.0, description: "2% cash back on gas")
            ],
            creditLimit: 15000.00,
            currentBalance: 3200.00,
            currentMonthSpend: 1800.00,
            isIncludedInOptimization: true,
            routingPriority: 0.7,
            institutionId: "inst-3"
        ),
        Card(
            id: "card-4",
            issuer: "Citi Double Cash",
            nickname: nil,
            last4: "3456",
            network: .mastercard,
            cardType: .credit,
            cardStyle: .platinum,
            status: .active,
            imageName: nil,
            rewardCategories: [
                RewardCategory(id: "cat-7", name: "All Purchases", multiplier: 2.0, description: "2% cash back on all purchases")
            ],
            creditLimit: 20000.00,
            currentBalance: 12000.00,
            currentMonthSpend: 4500.00,
            isIncludedInOptimization: true,
            routingPriority: 0.5,
            institutionId: "inst-4"
        )
    ]
    
    static let sampleInstitutions: [Institution] = [
        Institution(
            id: "inst-1",
            name: "American Express",
            logoAssetName: nil,
            description: "Credit cards and financial services",
            isSelected: false,
            connectionStatus: .notLinked
        ),
        Institution(
            id: "inst-2",
            name: "Chase",
            logoAssetName: nil,
            description: "Banking and credit cards",
            isSelected: false,
            connectionStatus: .notLinked
        ),
        Institution(
            id: "inst-3",
            name: "Bank of America",
            logoAssetName: nil,
            description: "Full-service banking",
            isSelected: false,
            connectionStatus: .notLinked
        ),
        Institution(
            id: "inst-4",
            name: "Citi",
            logoAssetName: nil,
            description: "Global banking",
            isSelected: false,
            connectionStatus: .notLinked
        ),
        Institution(
            id: "inst-5",
            name: "Wells Fargo",
            logoAssetName: nil,
            description: "Banking and financial services",
            isSelected: false,
            connectionStatus: .notLinked
        ),
        Institution(
            id: "inst-6",
            name: "Capital One",
            logoAssetName: nil,
            description: "Banking and credit cards",
            isSelected: false,
            connectionStatus: .notLinked
        )
    ]
    
    static let sampleCurrentMerchant: Merchant? = Merchant(
        id: "merchant-1",
        name: "Starbucks",
        category: .dining,
        address: "123 Campus Blvd, San Francisco, CA",
        location: Merchant.Location(latitude: 37.7749, longitude: -122.4194),
        iconName: "cup.and.saucer.fill"
    )
    
    static let sampleNearbyMerchants: [Merchant] = [
        Merchant(
            id: "merchant-1",
            name: "Starbucks",
            category: .dining,
            address: "123 Campus Blvd",
            location: Merchant.Location(latitude: 37.7749, longitude: -122.4194),
            iconName: "cup.and.saucer.fill"
        ),
        Merchant(
            id: "merchant-2",
            name: "Target",
            category: .shopping,
            address: "456 Market St",
            location: Merchant.Location(latitude: 37.7849, longitude: -122.4094),
            iconName: "cart.fill"
        ),
        Merchant(
            id: "merchant-3",
            name: "Chevron",
            category: .gas,
            address: "789 Main St",
            location: Merchant.Location(latitude: 37.7649, longitude: -122.4294),
            iconName: "fuelpump.fill"
        ),
        Merchant(
            id: "merchant-4",
            name: "Trader Joe's",
            category: .groceries,
            address: "321 Oak Ave",
            location: Merchant.Location(latitude: 37.7549, longitude: -122.4394),
            iconName: "cart.fill"
        )
    ]
    
    static let sampleRewardsSummary: RewardsSummary = RewardsSummary(
        currentMonthPoints: 12450,
        currentMonthValue: 124.50,
        previousMonthPoints: 10550,
        monthlyBreakdown: [
            MonthlyReward(id: "month-1", month: "Jul 2024", points: 8500, value: 85.00),
            MonthlyReward(id: "month-2", month: "Aug 2024", points: 9200, value: 92.00),
            MonthlyReward(id: "month-3", month: "Sep 2024", points: 10550, value: 105.50),
            MonthlyReward(id: "month-4", month: "Oct 2024", points: 11000, value: 110.00),
            MonthlyReward(id: "month-5", month: "Nov 2024", points: 11800, value: 118.00),
            MonthlyReward(id: "month-6", month: "Dec 2024", points: 12450, value: 124.50)
        ],
        categoryBreakdown: [
            CategoryReward(id: "cat-1", category: "Dining", points: 4500, percentage: 36.1),
            CategoryReward(id: "cat-2", category: "Groceries", points: 3200, percentage: 25.7),
            CategoryReward(id: "cat-3", category: "Travel", points: 2800, percentage: 22.5),
            CategoryReward(id: "cat-4", category: "Gas", points: 1200, percentage: 9.6),
            CategoryReward(id: "cat-5", category: "Other", points: 750, percentage: 6.1)
        ],
        cardContributions: [
            CardRewardContribution(
                id: "contrib-1",
                cardId: "card-1",
                cardName: "Amex Gold",
                points: 5200,
                tagline: "Most used at Restaurants"
            ),
            CardRewardContribution(
                id: "contrib-2",
                cardId: "card-2",
                cardName: "Chase Sapphire Reserve",
                points: 3800,
                tagline: "Best for Travel"
            ),
            CardRewardContribution(
                id: "contrib-3",
                cardId: "card-3",
                cardName: "BofA Customized Cash",
                points: 2500,
                tagline: "Top Groceries Card"
            ),
            CardRewardContribution(
                id: "contrib-4",
                cardId: "card-4",
                cardName: "Citi Double Cash",
                points: 950,
                tagline: "General Purpose"
            )
        ],
        optimizations: [
            OptimizationWin(
                id: "opt-1",
                title: "Amex Gold Routing",
                description: "We routed 12 purchases to Amex Gold and earned +3,600 extra points compared to using your default card.",
                pointsEarned: 3600,
                date: Date().addingTimeInterval(-86400 * 2)
            ),
            OptimizationWin(
                id: "opt-2",
                title: "BofA Groceries Optimization",
                description: "Automatically used BofA Customized Cash for 8 grocery purchases, earning +1,200 bonus points.",
                pointsEarned: 1200,
                date: Date().addingTimeInterval(-86400 * 5)
            ),
            OptimizationWin(
                id: "opt-3",
                title: "Chase Travel Bonus",
                description: "Routed 3 travel purchases to Chase Sapphire Reserve, maximizing your 3x travel rewards.",
                pointsEarned: 900,
                date: Date().addingTimeInterval(-86400 * 7)
            )
        ]
    )
    
    static let sampleRecommendations: [CardRecommendation] = [
        CardRecommendation(
            id: "rec-1",
            issuer: "Chase",
            cardName: "Chase Freedom Flex",
            logoAssetName: nil,
            categoryFocus: ["Groceries", "Online Shopping", "Rotating 5%"],
            estimatedYearlyBenefit: 180.0,
            explanation: "Perfect for maximizing grocery and online shopping rewards with rotating 5% categories.",
            tags: [.noAnnualFee, .beginnerFriendly],
            signUpBonus: "$200 after spending $500 in first 3 months",
            aprRange: "20.49% - 29.24% Variable APR",
            whyWeRecommend: [
                "No annual fee",
                "5% rotating categories match your spending",
                "Complements your existing Chase cards"
            ],
            isDismissed: false
        ),
        CardRecommendation(
            id: "rec-2",
            issuer: "American Express",
            cardName: "Amex Blue Cash Preferred",
            logoAssetName: nil,
            categoryFocus: ["Groceries", "Streaming", "Transit"],
            estimatedYearlyBenefit: 240.0,
            explanation: "6% cash back on groceries and streaming services could significantly boost your rewards.",
            tags: [.highRewards, .preApprovalLikely],
            signUpBonus: "$250 statement credit after spending $3,000 in first 6 months",
            aprRange: "19.24% - 29.99% Variable APR",
            whyWeRecommend: [
                "Highest grocery rewards rate available",
                "Streaming bonus matches your subscriptions",
                "Estimated $240/year additional value"
            ],
            isDismissed: false
        ),
        CardRecommendation(
            id: "rec-3",
            issuer: "Capital One",
            cardName: "Venture X",
            logoAssetName: nil,
            categoryFocus: ["Travel", "All Purchases"],
            estimatedYearlyBenefit: 320.0,
            explanation: "Premium travel card with excellent value proposition for frequent travelers.",
            tags: [.travelFocused, .highRewards],
            signUpBonus: "75,000 miles after spending $4,000 in first 3 months",
            aprRange: "21.24% - 28.24% Variable APR",
            whyWeRecommend: [
                "2x miles on all purchases",
                "Travel credits offset annual fee",
                "Premium travel benefits"
            ],
            isDismissed: false
        )
    ]
}

