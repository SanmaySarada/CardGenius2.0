//
//  CardDetailView.swift
//  CardGenius
//
//  Card Detail Sheet
//

import SwiftUI

struct CardDetailView: View {
    let card: Card
    @ObservedObject var viewModel: WalletViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: Int = 0
    @State private var routingPriority: Double
    @State private var isIncludedInOptimization: Bool
    
    init(card: Card, viewModel: WalletViewModel) {
        self.card = card
        self.viewModel = viewModel
        _routingPriority = State(initialValue: card.routingPriority)
        _isIncludedInOptimization = State(initialValue: card.isIncludedInOptimization)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Card Hero
                    CardView(
                        card: card,
                        isTopCard: true,
                        offset: 0,
                        scale: 1.0
                    )
                    .padding(Spacing.l)
                    
                    // Tabs
                    Picker("", selection: $selectedTab) {
                        Text("Summary").tag(0)
                        Text("Rewards").tag(1)
                        Text("Settings").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(Spacing.l)
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case 0:
                            SummaryTab(card: card)
                        case 1:
                            RewardsTab(card: card)
                        case 2:
                            SettingsTab(
                                card: card,
                                routingPriority: $routingPriority,
                                isIncludedInOptimization: $isIncludedInOptimization,
                                onSave: {
                                    var updatedCard = card
                                    updatedCard.routingPriority = routingPriority
                                    updatedCard.isIncludedInOptimization = isIncludedInOptimization
                                    Task {
                                        await viewModel.updateCard(updatedCard)
                                    }
                                    dismiss()
                                }
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .padding(Spacing.l)
                }
            }
            .navigationTitle(card.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SummaryTab: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            if let creditLimit = card.creditLimit {
                InfoRow(label: "Credit Limit", value: formatCurrency(creditLimit))
            }
            
            if let balance = card.currentBalance {
                InfoRow(label: "Current Balance", value: formatCurrency(balance))
            }
            
            InfoRow(label: "This Month's Spend", value: formatCurrency(card.currentMonthSpend))
            InfoRow(label: "Status", value: card.status.rawValue)
            InfoRow(label: "Card Number", value: card.maskedNumber)
            
            Button(action: {}) {
                HStack {
                    Text("Show Transactions")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.cgBody(17))
                .foregroundColor(.cgPrimary)
                .padding(Spacing.m)
                .background(Color.cgSecondaryBackground)
                .cornerRadius(Radius.medium)
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.cgBody(15))
                .foregroundColor(.cgSecondaryText)
            Spacer()
            Text(value)
                .font(.cgHeadline(15))
                .foregroundColor(.cgPrimaryText)
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct RewardsTab: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Reward Categories")
                .font(.cgHeadline(20))
                .foregroundColor(.cgPrimaryText)
            
            ForEach(card.rewardCategories) { category in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(category.name)
                            .font(.cgHeadline(17))
                            .foregroundColor(.cgPrimaryText)
                        Spacer()
                        Text("\(Int(category.multiplier))x")
                            .font(.cgHeadline(17))
                            .foregroundColor(.cgAccent)
                    }
                    
                    if let description = category.description {
                        Text(description)
                            .font(.cgBody(13))
                            .foregroundColor(.cgSecondaryText)
                    }
                }
                .padding(Spacing.m)
                .background(Color.cgSecondaryBackground)
                .cornerRadius(Radius.medium)
            }
        }
    }
}

struct SettingsTab: View {
    let card: Card
    @Binding var routingPriority: Double
    @Binding var isIncludedInOptimization: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Routing Priority")
                .font(.cgHeadline(17))
                .foregroundColor(.cgPrimaryText)
            
            VStack(spacing: Spacing.s) {
                Slider(value: $routingPriority, in: 0...1)
                
                HStack {
                    Text("Low")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgSecondaryText)
                    Spacer()
                    Text("High")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgSecondaryText)
                }
            }
            .padding(Spacing.m)
            .background(Color.cgSecondaryBackground)
            .cornerRadius(Radius.medium)
            
            Toggle("Include in optimization", isOn: $isIncludedInOptimization)
                .font(.cgBody(17))
                .padding(Spacing.m)
                .background(Color.cgSecondaryBackground)
                .cornerRadius(Radius.medium)
            
            Button(action: onSave) {
                Text("Save Changes")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Spacing.m)
        }
    }
}

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.l) {
                Text("Add a new card by connecting an institution")
                    .font(.cgBody(17))
                    .foregroundColor(.cgSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {}) {
                    Text("Connect Institution")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.l)
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

