//
//  Shadows.swift
//  CardGenius
//
//  Design System - Shadows
//

import SwiftUI

extension View {
    func cgCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    func cgElevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    func cgSubtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

