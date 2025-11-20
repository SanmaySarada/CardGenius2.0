//
//  CardServiceProtocol.swift
//  CardGenius
//
//  Card Service Protocol
//

import Foundation

protocol CardServiceProtocol {
    func fetchCards() async throws -> [Card]
    func refreshCards() async throws -> [Card]
    func updateCard(_ card: Card) async throws -> Card
    func getCard(id: String) async throws -> Card?
}

