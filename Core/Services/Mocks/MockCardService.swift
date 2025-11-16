//
//  MockCardService.swift
//  CardGenius
//
//  Mock Card Service Implementation
//

import Foundation

class MockCardService: CardServiceProtocol {
    private var cards: [Card] = []
    
    init() {
        // Initialize with mock data
        cards = MockData.sampleCards
    }
    
    func fetchCards() async throws -> [Card] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return cards
    }
    
    func refreshCards() async throws -> [Card] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        return cards
    }
    
    func updateCard(_ card: Card) async throws -> Card {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
        return card
    }
    
    func getCard(id: String) async throws -> Card? {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        return cards.first(where: { $0.id == id })
    }
}

