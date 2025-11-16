//
//  SkeletonLoader.swift
//  CardGenius
//
//  Skeleton Loading Component
//

import SwiftUI

struct SkeletonLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.medium)
            .fill(
                LinearGradient(
                    colors: [
                        Color.cgTertiaryBackground,
                        Color.cgTertiaryBackground.opacity(0.6),
                        Color.cgTertiaryBackground
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(x: isAnimating ? 200 : -200)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

struct CardSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.card)
            .fill(Color.cgTertiaryBackground)
            .frame(height: 220)
            .overlay(
                SkeletonLoader()
                    .mask(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .frame(height: 220)
                    )
            )
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        CardSkeletonView()
        CardSkeletonView()
    }
    .padding()
    .background(Color.cgBackground)
}

