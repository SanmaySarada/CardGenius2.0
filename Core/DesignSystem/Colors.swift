//
//  Colors.swift
//  CardGenius
//
//  Design System - Colors with Liquid Glass Effects
//

import SwiftUI

extension Color {
    // MARK: - Background Colors
    static var cgBackground: Color {
        Color(light: Color(red: 0.97, green: 0.97, blue: 0.99), dark: Color(red: 0.02, green: 0.02, blue: 0.04))
    }
    
    static var cgSecondaryBackground: Color {
        Color(light: Color(red: 0.94, green: 0.95, blue: 0.98), dark: Color(red: 0.05, green: 0.05, blue: 0.08))
    }
    
    static var cgTertiaryBackground: Color {
        Color(light: Color(red: 0.90, green: 0.92, blue: 0.96), dark: Color(red: 0.08, green: 0.08, blue: 0.12))
    }
    
    // MARK: - Glass Effects
    static var cgGlassLight: Color {
        Color.white.opacity(0.15)
    }
    
    static var cgGlassMedium: Color {
        Color.white.opacity(0.25)
    }
    
    static var cgGlassHeavy: Color {
        Color.white.opacity(0.4)
    }
    
    static var cgGlassDark: Color {
        Color.black.opacity(0.15)
    }
    
    // MARK: - Gradient Colors
    static var cgGradientStart: Color {
        Color(light: Color(red: 0.4, green: 0.6, blue: 1.0), dark: Color(red: 0.2, green: 0.4, blue: 0.9))
    }
    
    static var cgGradientEnd: Color {
        Color(light: Color(red: 0.7, green: 0.3, blue: 1.0), dark: Color(red: 0.5, green: 0.2, blue: 0.9))
    }
    
    static var cgAccentGradientStart: Color {
        Color(light: Color(red: 0.0, green: 0.7, blue: 0.9), dark: Color(red: 0.0, green: 0.6, blue: 0.8))
    }
    
    static var cgAccentGradientEnd: Color {
        Color(light: Color(red: 0.3, green: 0.9, blue: 0.7), dark: Color(red: 0.2, green: 0.8, blue: 0.6))
    }
    
    // MARK: - Primary Colors
    static var cgPrimary: Color {
        Color(light: Color(red: 0.1, green: 0.2, blue: 0.4), dark: Color(red: 0.3, green: 0.5, blue: 0.8))
    }
    
    static var cgAccent: Color {
        Color(light: Color(red: 0.0, green: 0.6, blue: 0.7), dark: Color(red: 0.2, green: 0.8, blue: 0.9))
    }
    
    // MARK: - Card Colors
    static var cgCardGold: Color {
        Color(light: Color(red: 0.85, green: 0.7, blue: 0.3), dark: Color(red: 0.9, green: 0.75, blue: 0.35))
    }
    
    static var cgCardPlatinum: Color {
        Color(light: Color(red: 0.7, green: 0.7, blue: 0.75), dark: Color(red: 0.8, green: 0.8, blue: 0.85))
    }
    
    static var cgCardBlack: Color {
        Color(light: Color(red: 0.15, green: 0.15, blue: 0.15), dark: Color(red: 0.1, green: 0.1, blue: 0.1))
    }
    
    static var cgCardBlue: Color {
        Color(light: Color(red: 0.2, green: 0.4, blue: 0.7), dark: Color(red: 0.3, green: 0.5, blue: 0.8))
    }
    
    // MARK: - Text Colors
    static var cgPrimaryText: Color {
        Color(light: .black, dark: .white)
    }
    
    static var cgSecondaryText: Color {
        Color(light: Color(red: 0.4, green: 0.4, blue: 0.4), dark: Color(red: 0.6, green: 0.6, blue: 0.6))
    }
    
    static var cgTertiaryText: Color {
        Color(light: Color(red: 0.6, green: 0.6, blue: 0.6), dark: Color(red: 0.5, green: 0.5, blue: 0.5))
    }
    
    // MARK: - Semantic Colors
    static var cgSuccess: Color {
        Color(light: Color(red: 0.2, green: 0.7, blue: 0.3), dark: Color(red: 0.3, green: 0.8, blue: 0.4))
    }
    
    static var cgWarning: Color {
        Color(light: Color(red: 1.0, green: 0.7, blue: 0.0), dark: Color(red: 1.0, green: 0.75, blue: 0.2))
    }
    
    static var cgError: Color {
        Color(light: Color(red: 0.9, green: 0.2, blue: 0.2), dark: Color(red: 1.0, green: 0.3, blue: 0.3))
    }
    
    // MARK: - Helper Initializer
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

