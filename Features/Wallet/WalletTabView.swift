//
//  WalletTabView.swift
//  CardGenius
//
//  Wallet Tab - Main Card Stack View
//

import SwiftUI
import UIKit
import CoreLocation

struct WalletTabView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: WalletViewModel
    @State private var selectedCard: Card?
    @State private var showingCardDetail: Bool = false
    @State private var showingAddCard: Bool = false
    @State private var showingSettings: Bool = false
    
    // Location change tracking for banner refresh
    @State private var lastKnownLocation: CLLocation?
    @State private var lastRefreshTime: Date?
    private let locationRefreshCooldown: TimeInterval = 3.0 // 3 seconds cooldown between refreshes
    private let minimumLocationChangeDistance: CLLocationDistance = 50.0 // 50 meters minimum change
    
    init() {
        // WARNING: Temporary initialization - services will be replaced in onAppear
        // This temporary MerchantService uses a NEW LocationManager that won't have location
        // The real services from ServiceContainer will be injected in onAppear
        // DO NOT load suggestions until after onAppear updates the services
        _viewModel = StateObject(wrappedValue: WalletViewModel(
            cardService: MockCardService(), // Keep for now as cards are local
            merchantService: MerchantService(locationManager: LocationManager(), cardService: MockCardService()),
            recommendationService: MockRecommendationService()
        ))
    }
    
    // Computed property to access location manager
    private var locationManager: LocationManager {
        serviceContainer.locationManager
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.cgBackground,
                        Color.cgSecondaryBackground,
                        Color.cgTertiaryBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .zIndex(0)
                
                if viewModel.isLoading {
                    VStack(spacing: Spacing.l) {
                        ForEach(0..<3) { _ in
                            CardSkeletonView()
                        }
                    }
                    .padding()
                    .zIndex(1)
                } else if viewModel.cards.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "No cards yet",
                        message: "Let's add some cards to get started",
                        actionTitle: "Add Card",
                        action: { showingAddCard = true }
                    )
                    .zIndex(1)
                } else {
                    // Main content
                    ScrollView {
                        VStack(spacing: Spacing.m) {
                            // Smart Suggestion Banner
                            if let suggestion = viewModel.currentSuggestion {
                                SmartSuggestionBanner(suggestion: suggestion) {
                                    // Scroll to recommended card
                                    if let card = viewModel.cards.first(where: { $0.id == suggestion.cardId }) {
                                        selectedCard = card
                                        showingCardDetail = true
                                    }
                                }
                                .padding(.horizontal, Spacing.l)
                                .padding(.top, Spacing.m)
                            }
                            
                            // Card Stack (z-index handled internally)
                            CardStackView(
                                cards: $viewModel.cards,
                                onCardTap: { card in
                                    selectedCard = card
                                    showingCardDetail = true
                                }
                            )
                            .padding(.vertical, Spacing.l)
                        }
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Spacing.m) {
                        Button(action: { showingAddCard = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.cgPrimary)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.cgPrimary)
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.cgPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCardDetail) {
                if let card = selectedCard {
                    CardDetailView(card: card, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                // CRITICAL: Initialize view model with services from environment FIRST
                // This ensures we use the real LocationManager from ServiceContainer, not a temporary one
                print("[WalletTabView] ===== ON APPEAR - CHECKING LOCATION =====")
                viewModel.cardService = serviceContainer.cardService
                viewModel.merchantService = serviceContainer.merchantService
                viewModel.recommendationService = serviceContainer.recommendationService
                
                // Debug location status
                serviceContainer.locationManager.checkLocationStatus()
                
                // Log location status
                if let location = serviceContainer.locationManager.userLocation {
                    print("[WalletTabView] ServiceContainer has location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    // If we already have location, set it as lastKnownLocation and load suggestion
                    lastKnownLocation = location
                    Task { @MainActor in
                        await viewModel.loadCurrentSuggestion()
                    }
                } else {
                    print("[WalletTabView] WARNING: ServiceContainer locationManager has NO location yet")
                    let status = serviceContainer.locationManager.authorizationStatus
                    print("[WalletTabView] Authorization status: \(status.rawValue)")
                    
                    if status == .denied {
                        print("[WalletTabView] ERROR: Location permission DENIED - user must enable in Settings")
                    } else if status == .notDetermined {
                        print("[WalletTabView] Location permission not determined - should prompt user")
                    }
                }
                print("[WalletTabView] ===== END ON APPEAR =====")
            }
            .task {
                // Wait for services to be properly injected from onAppear
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds to ensure services are injected
                
                // Verify we're using the real merchant service
                if let realService = viewModel.merchantService as? MerchantService {
                    print("[WalletTabView] Using real MerchantService with actual location")
                } else {
                    print("[WalletTabView] ERROR: Still using temporary/mock MerchantService!")
                }
                
                await viewModel.loadCards()
                
                // Try to load suggestion - if location isn't available, onChange will handle it when location arrives
                // loadCurrentSuggestion already has retry logic built in
                print("[WalletTabView] Initial attempt to load suggestion...")
                await viewModel.loadCurrentSuggestion()
                
                // FALLBACK: If initial load failed, periodically check for location
                // This handles cases where onChange might not fire properly
                if viewModel.currentSuggestion == nil {
                    print("[WalletTabView] Initial load failed - setting up periodic check for location")
                    
                    // Check every 1 second for up to 10 seconds
                    for i in 1...10 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        if let location = serviceContainer.locationManager.userLocation {
                            print("[WalletTabView] Location became available after \(i) seconds - loading suggestion")
                            lastKnownLocation = location
                            await viewModel.loadCurrentSuggestion()
                            
                            // If successful, break out of loop
                            if viewModel.currentSuggestion != nil {
                                print("[WalletTabView] Successfully loaded suggestion via periodic check")
                                break
                            }
                        }
                    }
                }
            }
            .onChange(of: serviceContainer.locationManager.authorizationStatus) { newStatus in
                // When permission is granted, trigger location refresh
                print("[WalletTabView] ===== AUTHORIZATION STATUS CHANGED IN VIEW =====")
                print("[WalletTabView] New authorization status: \(newStatus.rawValue)")
                
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    print("[WalletTabView] Permission granted - checking if location is available")
                    
                    // Small delay to let location update
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        // If we have location, load immediately
                        if let location = serviceContainer.locationManager.userLocation {
                            print("[WalletTabView] Permission granted and location available - loading suggestion")
                            lastKnownLocation = location
                            await viewModel.loadCurrentSuggestion()
                        } else {
                            print("[WalletTabView] Permission granted but no location yet - will load when location arrives")
                        }
                    }
                }
            }
            .onChange(of: serviceContainer.locationManager.userLocation) { newLocation in
                // STRICT: Only refresh banner when actual location changes significantly
                print("[WalletTabView] ===== LOCATION CHANGED IN VIEW =====")
                print("[WalletTabView] New location: \(newLocation?.coordinate.latitude ?? 0), \(newLocation?.coordinate.longitude ?? 0)")
                
                guard let newLocation = newLocation else {
                    // Location became unavailable - clear suggestion
                    print("[WalletTabView] Location became unavailable - clearing suggestion")
                    Task { @MainActor in
                        viewModel.currentSuggestion = nil
                    }
                    lastKnownLocation = nil
                    return
                }
                
                // Check if location changed significantly
                if let lastLocation = lastKnownLocation {
                    let distance = newLocation.distance(from: lastLocation)
                    
                    // Only refresh if moved more than minimum distance
                    if distance < minimumLocationChangeDistance {
                        print("[WalletTabView] Location change too small (\(Int(distance))m) - skipping refresh")
                        return
                    }
                    
                    // Check cooldown period
                    if let lastRefresh = lastRefreshTime {
                        let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
                        if timeSinceRefresh < locationRefreshCooldown {
                            print("[WalletTabView] Location refresh cooldown active (\(Int(timeSinceRefresh))s) - skipping refresh")
                            return
                        }
                    }
                    
                    print("[WalletTabView] Location changed significantly (\(Int(distance))m) - refreshing suggestion")
                } else {
                    // FIRST location update - ALWAYS load suggestion
                    print("[WalletTabView] ===== FIRST LOCATION RECEIVED - LOADING BANNER =====")
                    print("[WalletTabView] Location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                }
                
                // Update tracking state
                lastKnownLocation = newLocation
                lastRefreshTime = Date()
                
                // Refresh suggestion based on new actual location
                print("[WalletTabView] Triggering loadCurrentSuggestion()...")
                Task { @MainActor in
                    await viewModel.loadCurrentSuggestion()
                }
            }
        }
    }
}

struct SmartSuggestionBanner: View {
    let suggestion: CardSuggestion
    let onTap: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.m) {
                // Card Image or fallback icon
                if let imageName = suggestion.cardImageName, !imageName.isEmpty,
                   let uiImage = UIImage(named: "card_images/\(imageName)") ?? UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 36)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.cgAccentGradientStart.opacity(0.6),
                                            Color.cgAccentGradientEnd.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.cgAccent.opacity(0.4), radius: 12)
                } else {
                    // Fallback to sparkles icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cgAccentGradientStart.opacity(0.3),
                                        Color.cgAccentGradientEnd.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    }
                    .shadow(color: Color.yellow.opacity(0.4), radius: 12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("You're at \(suggestion.merchantName)")
                        .font(.cgSubheadline(14))
                        .fontWeight(.semibold)
                        .foregroundColor(.cgPrimaryText)
                    
                    Text("Use \(suggestion.cardName) for \(suggestion.rewardText)")
                        .font(.cgCaption(12))
                        .foregroundColor(.cgSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cgAccentGradientStart, Color.cgAccentGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(Spacing.m)
            .liquidGlassCard(cornerRadius: Radius.large)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct CardStackView: View {
    @Binding var cards: [Card]
    let onCardTap: (Card) -> Void
    
    @State private var lastTopCardMovedTime: Date? = nil
    
    private let cardHeight: CGFloat = 220
    private let cardSpacing: CGFloat = 25
    private let cardOverlap: CGFloat = 140
    private let tapCooldown: TimeInterval = 1.0 // 1 second cooldown
    
    var body: some View {
        VStack(spacing: -cardOverlap) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isTopCard = index == 0
                    
                    CardView(
                        card: card,
                        isTopCard: isTopCard,
                        offset: CGFloat(index) * cardSpacing,
                        scale: 1.0
                    )
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, index == 0 ? 0 : cardSpacing)
                    .zIndex(Double(cards.count - index))
                    .onTapGesture {
                        // Check if this card is already at the top
                        if index == 0 {
                            // Card is at the top - check cooldown before opening
                            let now = Date()
                            if let lastMoved = lastTopCardMovedTime {
                                let timeSinceMove = now.timeIntervalSince(lastMoved)
                                if timeSinceMove >= tapCooldown {
                                    // Cooldown has passed - open card detail
                                    onCardTap(card)
                                }
                            } else {
                                // No recent move - open card detail
                                onCardTap(card)
                            }
                        } else {
                            // Card is not at top - move it to top
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                if let tappedIndex = cards.firstIndex(where: { $0.id == card.id }) {
                                    let tappedCard = cards.remove(at: tappedIndex)
                                    cards.insert(tappedCard, at: 0)
                                    // Record the time when card moved to top
                                    lastTopCardMovedTime = Date()
                                }
                            }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press opens card detail view
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onCardTap(card)
                        }
                    }
                }
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl + cardHeight) // Extra padding to see bottom of last card
    }
}

