//
//  RewardsViewModel.swift
//  CardGenius
//
//  Rewards View Model
//

import Foundation

@MainActor
class RewardsViewModel: ObservableObject {
    @Published var rewardsSummary: RewardsSummary?
    
    var rewardsService: RewardsServiceProtocol
    
    init(rewardsService: RewardsServiceProtocol) {
        self.rewardsService = rewardsService
    }
    
    func loadRewardsSummary() async {
        do {
            rewardsSummary = try await rewardsService.fetchRewardsSummary()
        } catch {
            print("Error loading rewards summary: \(error)")
        }
    }
}

