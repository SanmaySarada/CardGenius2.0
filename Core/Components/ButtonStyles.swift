//
//  ButtonStyles.swift
//  CardGenius
//
//  Custom Button Styles
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(.cgHeadline(17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .background(Color.cgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(.cgHeadline(17))
            .foregroundColor(.cgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .background(Color.cgPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct PillButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    init(backgroundColor: Color = Color.cgAccent) {
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(.cgSubheadline(15))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
