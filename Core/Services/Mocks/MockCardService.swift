//
//  MockCardService.swift
//  CardGenius
//
//  Mock Card Service Implementation
//

import Foundation
import SwiftUI

class MockCardService: CardServiceProtocol {
    private var cards: [Card] = []
    
    init() {
        // Prefer generating from bundled CSV with images; fallback to MockData
        if let generated = Self.generateCardsFromCSV() {
            cards = generated
        } else {
            cards = MockData.sampleCards
        }
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

// MARK: - CSV -> Cards generation
extension MockCardService {
    private static func generateCardsFromCSV() -> [Card]? {
        guard let csvURL = Bundle.main.url(forResource: "card_rewards_matrix_temp2", withExtension: "csv") else {
            return nil
        }
        guard let imagesFolderURL = Bundle.main.url(forResource: "card_images", withExtension: nil) else {
            return nil
        }
        // Index images by normalized name (lowercased, alnum only)
        let imageNames = Self.collectImageNames(at: imagesFolderURL)
        
        // Read first column (Card Name)
        guard let content = try? String(contentsOf: csvURL, encoding: .utf8) else { return nil }
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }
        
        // Skip header, build 1:1 card list
        var generated: [Card] = []
        for (idx, line) in lines.enumerated() {
            if idx == 0 { continue } // header
            // naive CSV split (card name has no commas typically; acceptable for mock)
            let name = line.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? "Card \(idx)"
            let issuer = name
            let last4 = String(format: "%04d", Int.random(in: 0...9999))
            let network: CardNetwork = Self.inferNetwork(from: name)
            let style: CardStyle = .gradient
            let status: CardStatus = .active
            let categories = [RewardCategory(id: "cat-\(idx)", name: "General", multiplier: 1.0, description: nil)]
            let imageName = Self.matchImageName(for: name, in: imageNames)
            if idx <= 5 { // Log first 5 for debugging
                print("🃏 Card: '\(name)' → Image: '\(imageName ?? "NONE")'")
            }
            let creditLimit = Double.random(in: 5000...50000)
            let currentBalance = Double.random(in: 0...creditLimit * 0.7)
            let monthSpend = Double.random(in: 0...5000)
            
            let card = Card(
                id: "csv-\(idx)",
                issuer: issuer,
                nickname: nil,
                last4: last4,
                network: network,
                cardType: .credit,
                cardStyle: style,
                status: status,
                imageName: imageName,
                rewardCategories: categories,
                creditLimit: creditLimit,
                currentBalance: currentBalance,
                currentMonthSpend: monthSpend,
                isIncludedInOptimization: true,
                routingPriority: Double.random(in: 0.3...1.0),
                institutionId: "inst-\(idx % 5)"
            )
            generated.append(card)
        }
        // Return only 4 random cards
        return Array(generated.shuffled().prefix(4))
    }
    
    private static func collectImageNames(at folderURL: URL) -> [String] {
        var results: [String] = []
        if let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ["png", "jpg", "jpeg", "webp"].contains(ext) {
                    results.append(fileURL.lastPathComponent)
                }
            }
        }
        print("📸 Found \(results.count) card images in bundle")
        if results.isEmpty {
            print("⚠️ No images found! Checking what's in main bundle...")
            if let bundlePath = Bundle.main.resourcePath {
                print("Bundle path: \(bundlePath)")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) {
                    print("Bundle contents (first 10): \(contents.prefix(10))")
                }
            }
        } else {
            print("📸 Sample images: \(results.prefix(5))")
        }
        return results
    }
    
    private static func normalize(_ s: String) -> String {
        return s.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "", options: .regularExpression)
    }
    
    private static func matchImageName(for cardName: String, in imageNames: [String]) -> String? {
        let target = normalize(cardName)
        // simple contains/fuzzy match
        let scored = imageNames.map { imageName -> (String, Int) in
            let base = normalize((imageName as NSString).deletingPathExtension)
            let score = base.commonPrefix(with: target).count
            return (imageName, score)
        }
        let best = scored.max { a, b in a.1 < b.1 }
        if let best = best, best.1 >= 4 {
            return best.0 // usable with Image(best)
        }
        return nil
    }
    
    private static func inferNetwork(from name: String) -> CardNetwork {
        let lower = name.lowercased()
        if lower.contains("amex") || lower.contains("american express") { return .amex }
        if lower.contains("visa") || lower.contains("chase sapphire") || lower.contains("capital one") { return .visa }
        if lower.contains("mastercard") || lower.contains("citi") { return .mastercard }
        if lower.contains("discover") { return .discover }
        return .visa
    }
}

