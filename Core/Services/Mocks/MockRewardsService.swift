//
//  MockRewardsService.swift
//  CardGenius
//
//  Mock Rewards Service Implementation
//

import Foundation

class MockRewardsService: RewardsServiceProtocol {
    func fetchRewardsSummary() async throws -> RewardsSummary {
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        return MockData.sampleRewardsSummary
    }
}

