//
//  PlacesTabView.swift
//  CardGenius
//
//  Places / Map Tab
//

import SwiftUI
import MapKit

struct PlacesTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: PlacesViewModel
    @State private var showingBottomSheet: Bool = true
    @State private var selectedMerchant: Merchant?
    
    init() {
        _viewModel = StateObject(wrappedValue: PlacesViewModel(
            merchantService: MockMerchantService(),
            cardService: MockCardService()
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )), annotationItems: viewModel.nearbyMerchants) { merchant in
                    MapAnnotation(coordinate: merchant.location.coordinate) {
                        Button(action: {
                            selectedMerchant = merchant
                            viewModel.selectMerchant(merchant)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cgAccentGradientStart.opacity(0.8), Color.cgAccentGradientEnd.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: merchant.category.iconName)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .shadow(color: Color.cgAccent.opacity(0.4), radius: 12)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Bottom Sheet
                if let currentMerchant = viewModel.currentMerchant {
                    BottomSheet(isPresented: $showingBottomSheet, collapsedHeight: 140, expandedHeight: 500) {
                        MerchantBottomSheetContent(
                            merchant: currentMerchant,
                            recommendedCard: viewModel.recommendedCard,
                            alternativeCard: viewModel.alternativeCard,
                            onViewCard: {},
                            onWhyThisCard: {}
                        )
                    }
                }
            }
            .navigationTitle("Places")
            .onAppear {
                viewModel.merchantService = serviceContainer.merchantService
                viewModel.cardService = serviceContainer.cardService
            }
            .task {
                await viewModel.loadCurrentMerchant()
                await viewModel.loadNearbyMerchants()
            }
        }
    }
}

struct MerchantBottomSheetContent: View {
    let merchant: Merchant
    let recommendedCard: Card?
    let alternativeCard: Card?
    let onViewCard: () -> Void
    let onWhyThisCard: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                // Merchant Header
                HStack(spacing: Spacing.m) {
                    Image(systemName: merchant.category.iconName)
                        .font(.title2)
                        .foregroundColor(.cgPrimary)
                        .frame(width: 50, height: 50)
                        .background(Color.cgPrimary.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(merchant.name)
                            .font(.cgHeadline(20))
                            .foregroundColor(.cgPrimaryText)
                        
                        Text(merchant.address)
                            .font(.cgBody(13))
                            .foregroundColor(.cgSecondaryText)
                    }
                }
                .padding(.bottom, Spacing.s)
                
                // Category Chip
                Text(merchant.category.rawValue)
                    .font(.cgCaption(12))
                    .foregroundColor(.cgPrimary)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.cgPrimary.opacity(0.1))
                    .cornerRadius(Radius.pill)
                
                Divider()
                    .padding(.vertical, Spacing.m)
                
                // Recommended Card
                if let card = recommendedCard {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text("Best card")
                            .font(.cgHeadline(17))
                            .foregroundColor(.cgPrimaryText)
                        
                        HStack(spacing: Spacing.m) {
                            RoundedRectangle(cornerRadius: Radius.small)
                                .fill(card.cardStyle.gradient)
                                .frame(width: 60, height: 40)
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(card.displayName)
                                    .font(.cgHeadline(15))
                                    .foregroundColor(.cgPrimaryText)
                                
                                if let topCategory = card.rewardCategories.first {
                                    Text("You earn ~\(Int(topCategory.multiplier))x points here")
                                        .font(.cgCaption(12))
                                        .foregroundColor(.cgSecondaryText)
                                }
                            }
                        }
                        .padding(Spacing.m)
                        .background(Color.cgSecondaryBackground)
                        .cornerRadius(Radius.medium)
                        
                        if let altCard = alternativeCard {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Alt option: \(altCard.displayName)")
                                    .font(.cgBody(13))
                                    .foregroundColor(.cgSecondaryText)
                            }
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, Spacing.m)
                
                // Explanation
                Text("Determined by category + your current cards")
                    .font(.cgCaption(12))
                    .foregroundColor(.cgTertiaryText)
                
                // Action Buttons
                VStack(spacing: Spacing.m) {
                    Button(action: onViewCard) {
                        Text("View this card in Wallet")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button(action: onWhyThisCard) {
                        Text("Why this card?")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, Spacing.m)
            }
            .padding(Spacing.l)
        }
    }
}

