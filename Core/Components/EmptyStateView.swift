//
//  EmptyStateView.swift
//  CardGenius
//
//  Empty State Component
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.cgSecondaryText)
            
            VStack(spacing: Spacing.s) {
                Text(title)
                    .font(.cgHeadline(20))
                    .foregroundColor(.cgPrimaryText)
                
                Text(message)
                    .font(.cgBody(15))
                    .foregroundColor(.cgSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.m)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

#Preview {
    EmptyStateView(
        icon: "creditcard",
        title: "No cards yet",
        message: "Let's add some cards to get started",
        actionTitle: "Add Card",
        action: {}
    )
}

