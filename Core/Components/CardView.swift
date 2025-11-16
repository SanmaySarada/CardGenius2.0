//
//  CardView.swift
//  CardGenius
//
//  Card Display Component
//

import SwiftUI

struct CardView: View {
    let card: Card
    let isTopCard: Bool
    let offset: CGFloat
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(card.cardStyle.gradient)
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    // Card Content
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        HStack {
                            // Network Icon
                            Image(systemName: card.network.iconName)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            // Status Pill
                            StatusPill(status: card.status)
                        }
                        
                        Spacer()
                        
                        // Card Number
                        Text(card.maskedNumber)
                            .font(.cgTitle(24, weight: .semibold))
                            .foregroundColor(.white)
                            .tracking(4)
                        
                        // Card Name
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(card.displayName)
                                .font(.cgHeadline(18))
                                .foregroundColor(.white.opacity(0.95))
                            
                            if let topCategory = card.rewardCategories.first {
                                HStack(spacing: Spacing.s) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.cgAccent)
                                    Text("\(Int(topCategory.multiplier))x \(topCategory.name)")
                                        .font(.cgCaption(11))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    .padding(Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
                .cgCardShadow()
        }
        .scaleEffect(scale)
        .offset(y: offset)
        .opacity(isTopCard ? 1.0 : 0.6)
    }
}

struct StatusPill: View {
    let status: CardStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.cgCaption(10))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.8))
            .cornerRadius(Radius.pill)
    }
}

#Preview {
    ZStack {
        Color.cgBackground
        CardView(
            card: MockData.sampleCards[0],
            isTopCard: true,
            offset: 0,
            scale: 1.0
        )
        .padding()
    }
}

