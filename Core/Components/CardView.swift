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
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Base Card with Gradient
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(card.cardStyle.gradient)
                .frame(height: 220)
            
            // Glass overlay layer
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
            
            // Animated shimmer effect
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .mask(RoundedRectangle(cornerRadius: Radius.card))
            
            // Subtle inner glow
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            
            // Card Content with glass background
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack {
                    // Network Icon with glow
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: card.network.iconName)
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: .white.opacity(0.3), radius: 8)
                    
                    Spacer()
                    
                    // Enhanced Status Pill
                    StatusPill(status: card.status)
                }
                
                Spacer()
                
                // Card Number with enhanced styling
                Text(card.maskedNumber)
                    .font(.cgTitle(26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(6)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Card Name with glass background
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(card.displayName)
                        .font(.cgHeadline(18))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                    
                    if let topCategory = card.rewardCategories.first {
                        HStack(spacing: Spacing.s) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .yellow.opacity(0.6), radius: 4)
                            
                            Text("\(Int(topCategory.multiplier))x \(topCategory.name)")
                                .font(.cgCaption(11))
                                .foregroundColor(.white.opacity(0.95))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Radius.pill)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 220)
        .shadow(color: Color.cgAccent.opacity(0.2), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .scaleEffect(scale)
        .offset(y: offset)
        .opacity(isTopCard ? 1.0 : 0.7)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

struct StatusPill: View {
    let status: CardStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.cgCaption(10))
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    Capsule()
                        .fill(status.color.opacity(0.7))
                    
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                }
            )
            .shadow(color: status.color.opacity(0.5), radius: 6, x: 0, y: 3)
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

