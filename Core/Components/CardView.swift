//
//  CardView.swift
//  CardGenius
//
//  Card Display Component
//

import SwiftUI
import UIKit
import CoreImage

struct CardView: View {
    let card: Card
    let isTopCard: Bool
    let offset: CGFloat
    let scale: CGFloat
    @State private var shimmerOffset: CGFloat = -200
    @State private var isLightCard: Bool = false
    
    // Determine if card is light (needs black text)
    private func checkIfLightCard() {
        if let imageName = card.imageName, !imageName.isEmpty,
           let uiImage = UIImage(named: "card_images/\(imageName)") ?? UIImage(named: imageName) {
            // Check image brightness
            isLightCard = uiImage.averageBrightness > 0.6
        } else {
            // Check gradient/card style - platinum and gold are light
            isLightCard = card.cardStyle == .platinum || card.cardStyle == .gold
        }
    }
    
    var body: some View {
        ZStack {
            // Base Card Background: Real card image or gradient fallback
            if let imageName = card.imageName, !imageName.isEmpty,
               let uiImage = UIImage(named: "card_images/\(imageName)") ?? UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            } else {
                // Clean gradient background when no image
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(card.cardStyle.gradient)
                    .frame(height: 220)
            }
            
            // Subtle border glow
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear,
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Card Content - always displayed on top
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack {
                    Spacer()
                    
                    // Enhanced Status Pill
                    StatusPill(status: card.status)
                }
                
                Spacer()
                
                // Card Number with enhanced styling
                Text(card.maskedNumber)
                    .font(.cgTitle(26, weight: .bold))
                    .foregroundStyle(
                        isLightCard ?
                        LinearGradient(
                            colors: [.black, .black.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(6)
                    .shadow(color: isLightCard ? .white.opacity(0.3) : .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Card Name with glass background
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(card.displayName)
                        .font(.cgHeadline(18))
                        .foregroundColor(isLightCard ? .black : .white)
                        .fontWeight(.semibold)
                        .shadow(color: isLightCard ? .white.opacity(0.3) : .black.opacity(0.2), radius: 2)
                    
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
                                .foregroundColor(isLightCard ? .black.opacity(0.9) : .white.opacity(0.95))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Radius.pill)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .strokeBorder(isLightCard ? Color.black.opacity(0.2) : Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 220)
        .cornerRadius(Radius.card)
        .shadow(color: Color.black.opacity(isTopCard ? 0.25 : 0.15), radius: isTopCard ? 30 : 20, x: 0, y: isTopCard ? 15 : 10)
        .shadow(color: Color.cgAccent.opacity(isTopCard ? 0.15 : 0.1), radius: isTopCard ? 25 : 15, x: 0, y: isTopCard ? 12 : 8)
        .scaleEffect(scale)
        .offset(y: offset)
        .onAppear {
            checkIfLightCard()
        }
        .onChange(of: card.imageName) { _ in
            checkIfLightCard()
        }
    }
}

// MARK: - UIImage Brightness Extension
extension UIImage {
    var averageBrightness: Double {
        guard let cgImage = self.cgImage else { return 0.5 }
        
        let context = CIContext()
        guard let ciImage = CIImage(image: self) else { return 0.5 }
        
        // Create a small thumbnail for faster processing
        let scale = min(100.0 / self.size.width, 100.0 / self.size.height)
        let thumbnailSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        
        guard let thumbnail = context.createCGImage(ciImage, from: CGRect(origin: .zero, size: thumbnailSize)) else {
            return 0.5
        }
        
        let width = thumbnail.width
        let height = thumbnail.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return 0.5
        }
        
        context.draw(thumbnail, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalBrightness: Double = 0
        let pixelCount = width * height
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            
            // Calculate brightness using luminance formula
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            totalBrightness += brightness
        }
        
        return totalBrightness / Double(pixelCount)
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

