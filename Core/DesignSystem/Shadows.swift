//
//  Shadows.swift
//  CardGenius
//
//  Design System - Shadows & Glass Effects
//

import SwiftUI

extension View {
    // MARK: - Traditional Shadows
    func cgCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    func cgElevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    func cgSubtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Glass Morphism Effects
    func glassBackground(blurStyle: UIBlurEffect.Style = .systemThinMaterial) -> some View {
        self.background(GlassBackgroundView(blurStyle: blurStyle))
    }
    
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.background(
            ZStack {
                // Glass effect with blur
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border highlight
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .cgElevatedShadow()
    }
    
    func liquidGlassCard(cornerRadius: CGFloat = 24) -> some View {
        self.background(
            ZStack {
                // Base glass layer
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                
                // Animated gradient shimmer
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cgAccentGradientStart.opacity(0.15),
                                Color.cgAccentGradientEnd.opacity(0.15),
                                Color.cgGradientStart.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass border with glow
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.cgAccent.opacity(0.15), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func glowEffect(color: Color = .cgAccent, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: radius / 2)
    }
}

// MARK: - Glass Background View
struct GlassBackgroundView: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

