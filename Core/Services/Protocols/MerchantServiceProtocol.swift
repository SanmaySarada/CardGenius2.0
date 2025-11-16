//
//  MerchantServiceProtocol.swift
//  CardGenius
//
//  Merchant Service Protocol
//

import Foundation

protocol MerchantServiceProtocol {
    func getCurrentMerchant() async throws -> Merchant?
    func getNearbyMerchants() async throws -> [Merchant]
    func getRecommendedCard(for merchant: Merchant) async throws -> Card?
}

