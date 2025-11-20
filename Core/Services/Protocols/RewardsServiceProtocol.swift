//
//  RewardsServiceProtocol.swift
//  CardGenius
//
//  Rewards Service Protocol
//

import Foundation

protocol RewardsServiceProtocol {
    func fetchRewardsSummary() async throws -> RewardsSummary
}

