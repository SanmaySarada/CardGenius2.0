//
//  OnboardingFlowView.swift
//  CardGenius
//
//  Onboarding Flow
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: OnboardingViewModel
    @State private var currentPage: Int = 0
    
    init() {
        // Temporary initialization, will be updated in onAppear
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            institutionService: MockInstitutionService(),
            cardService: MockCardService()
        ))
    }
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView(onNext: { currentPage = 1 })
                .tag(0)
            
            SelectBanksView(viewModel: viewModel, onNext: { currentPage = 2 })
                .tag(1)
            
            ConnectAccountsView(viewModel: viewModel, onNext: { currentPage = 3 })
                .tag(2)
            
            SyncCardsView(viewModel: viewModel, onComplete: {
                appState.completeOnboarding()
            })
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
        .onAppear {
            // Initialize view model with services from environment
            viewModel.institutionService = serviceContainer.institutionService
            viewModel.cardService = serviceContainer.cardService
            Task {
                await viewModel.loadInstitutions()
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onNext: () -> Void
    @State private var showPrivacyInfo = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.cgGradientStart.opacity(0.1),
                    Color.cgGradientEnd.opacity(0.15),
                    Color.cgAccentGradientStart.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Enhanced Animated Card Stack with Glass Effect
                ZStack {
                    ForEach(0..<3) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.card)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cgGradientStart, Color.cgGradientEnd, Color.cgAccentGradientStart],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: Radius.card)
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                            
                            RoundedRectangle(cornerRadius: Radius.card)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                        .frame(width: 300, height: 190)
                        .offset(x: CGFloat(index) * 12, y: CGFloat(index) * 12)
                        .rotationEffect(.degrees(Double(index) * 4))
                        .opacity(1.0 - Double(index) * 0.15)
                        .shadow(color: Color.cgAccent.opacity(0.3 - Double(index) * 0.1), radius: 20, x: 0, y: 10)
                    }
                }
                .padding(.bottom, Spacing.xxl)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showPrivacyInfo)
                
                VStack(spacing: Spacing.m) {
                    Text("Welcome to CardGenius")
                        .font(.cgTitle(38))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cgGradientStart, Color.cgGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("A smarter wallet that routes your cards for maximum rewards.")
                        .font(.cgBody(18))
                        .foregroundColor(.cgSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                
                Spacer()
                
                VStack(spacing: Spacing.m) {
                    Button(action: onNext) {
                        Text("Get Started")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                    
                    Button(action: { showPrivacyInfo = true }) {
                        Text("Learn More")
                            .font(.cgBody(17))
                            .foregroundColor(.cgPrimary)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(.bottom, Spacing.xxl)
            }
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyInfoView()
        }
    }
}

struct PrivacyInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.cgAccent)
                        .padding(.bottom, Spacing.s)
                    
                    Text("Your Privacy Matters")
                        .font(.cgHeadline(24))
                        .foregroundColor(.cgPrimaryText)
                    
                    Text("CardGenius is designed with privacy at its core. We never store your full card numbers (PANs). We only store metadata and tokens from your connected institutions to help optimize your rewards.")
                        .font(.cgBody(17))
                        .foregroundColor(.cgSecondaryText)
                }
                .padding(Spacing.l)
                
                Spacer()
            }
            .navigationTitle("Privacy")
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

// MARK: - Select Banks View
struct SelectBanksView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var selectedCount: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.m) {
                Text("Select Your Banks")
                    .font(.cgTitle(28))
                    .foregroundColor(.cgPrimaryText)
                    .padding(.top, Spacing.xxl)
                
                Text("Choose the institutions you'd like to connect")
                    .font(.cgBody(15))
                    .foregroundColor(.cgSecondaryText)
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.l)
            
            // Institution Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.m),
                    GridItem(.flexible(), spacing: Spacing.m)
                ], spacing: Spacing.m) {
                    ForEach(viewModel.institutions) { institution in
                        InstitutionTile(
                            institution: institution,
                            isSelected: institution.isSelected
                        ) {
                            viewModel.toggleInstitution(institution)
                            selectedCount = viewModel.institutions.filter { $0.isSelected }.count
                        }
                    }
                }
                .padding(Spacing.l)
            }
            
            // Footer
            VStack(spacing: Spacing.m) {
                if selectedCount > 0 {
                    Text("You've selected \(selectedCount) institution\(selectedCount == 1 ? "" : "s")")
                        .font(.cgSubheadline(15))
                        .foregroundColor(.cgSecondaryText)
                }
                
                Button(action: {
                    if selectedCount > 0 {
                        onNext()
                    }
                }) {
                    Text("Continue to connect accounts")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedCount == 0)
                .opacity(selectedCount > 0 ? 1.0 : 0.5)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.l)
            }
        }
        .onAppear {
            selectedCount = viewModel.institutions.filter { $0.isSelected }.count
        }
    }
}

struct InstitutionTile: View {
    let institution: Institution
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.m) {
                // Logo placeholder
                RoundedRectangle(cornerRadius: Radius.medium)
                    .fill(Color.cgTertiaryBackground)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(institution.name.prefix(1)))
                            .font(.cgHeadline(24))
                            .foregroundColor(.cgSecondaryText)
                    )
                
                Text(institution.name)
                    .font(.cgSubheadline(13))
                    .foregroundColor(.cgPrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.medium)
                    .fill(isSelected ? Color.cgPrimary.opacity(0.1) : Color.cgSecondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.medium)
                            .stroke(isSelected ? Color.cgPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Connect Accounts View
struct ConnectAccountsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var showingConnectSheet: Institution?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.m) {
                Text("Connect Accounts")
                    .font(.cgTitle(28))
                    .foregroundColor(.cgPrimaryText)
                    .padding(.top, Spacing.xxl)
                
                Text("Link your selected institutions")
                    .font(.cgBody(15))
                    .foregroundColor(.cgSecondaryText)
            }
            .padding(.bottom, Spacing.l)
            
            // Institution List
            ScrollView {
                VStack(spacing: Spacing.m) {
                    ForEach(viewModel.selectedInstitutions) { institution in
                        InstitutionConnectionRow(
                            institution: institution,
                            onConnect: {
                                showingConnectSheet = institution
                            }
                        )
                    }
                }
                .padding(Spacing.l)
            }
            
            // Continue Button
            if viewModel.allInstitutionsLinked {
                Button(action: onNext) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.l)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $showingConnectSheet) { institution in
            ConnectInstitutionView(
                institution: institution,
                onComplete: {
                    Task {
                        await viewModel.linkInstitution(institution)
                    }
                    showingConnectSheet = nil
                }
            )
        }
    }
}

struct InstitutionConnectionRow: View {
    let institution: Institution
    let onConnect: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.m) {
            // Logo
            RoundedRectangle(cornerRadius: Radius.small)
                .fill(Color.cgTertiaryBackground)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(institution.name.prefix(1)))
                        .font(.cgHeadline(20))
                        .foregroundColor(.cgSecondaryText)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(institution.name)
                    .font(.cgHeadline(17))
                    .foregroundColor(.cgPrimaryText)
                
                Text(institution.connectionStatus.rawValue)
                    .font(.cgCaption(13))
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            if institution.connectionStatus == .notLinked {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.cgSubheadline(15))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.s)
                        .background(Color.cgPrimary)
                        .cornerRadius(Radius.medium)
                }
            } else if institution.connectionStatus == .linking {
                ProgressView()
                    .padding(.horizontal, Spacing.m)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.cgSuccess)
                    .font(.title3)
            }
        }
        .padding(Spacing.m)
        .background(Color.cgSecondaryBackground)
        .cornerRadius(Radius.medium)
    }
    
    private var statusColor: Color {
        switch institution.connectionStatus {
        case .linked: return .cgSuccess
        case .linking: return .cgWarning
        case .error: return .cgError
        case .notLinked: return .cgSecondaryText
        }
    }
}

struct ConnectInstitutionView: View {
    let institution: Institution
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isConnecting: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.m) {
                    RoundedRectangle(cornerRadius: Radius.medium)
                        .fill(Color.cgTertiaryBackground)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(institution.name.prefix(1)))
                                .font(.cgHeadline(32))
                                .foregroundColor(.cgSecondaryText)
                        )
                    
                    Text("Connect \(institution.name)")
                        .font(.cgHeadline(24))
                        .foregroundColor(.cgPrimaryText)
                }
                .padding(.top, Spacing.xxl)
                
                VStack(spacing: Spacing.m) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, Spacing.l)
                
                Spacer()
                
                Button(action: {
                    isConnecting = true
                    // Simulate connection delay
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        isConnecting = false
                        onComplete()
                        dismiss()
                    }
                }) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || isConnecting)
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.l)
            }
            .navigationTitle("Connect Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sync Cards View
struct SyncCardsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    @State private var foundCards: [Card] = []
    @State private var isSyncing: Bool = true
    @State private var syncProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxl)
            
            if isSyncing {
                VStack(spacing: Spacing.l) {
                    ProgressView(value: syncProgress)
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .tint(.cgAccent)
                    
                    Text("Finding your cards…")
                        .font(.cgHeadline(20))
                        .foregroundColor(.cgPrimaryText)
                    
                    Text("\(foundCards.count) found")
                        .font(.cgBody(15))
                        .foregroundColor(.cgSecondaryText)
                }
            } else {
                VStack(spacing: Spacing.l) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.cgSuccess)
                    
                    Text("\(foundCards.count) cards found!")
                        .font(.cgHeadline(24))
                        .foregroundColor(.cgPrimaryText)
                    
                    // Show discovered cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.m) {
                            ForEach(foundCards.prefix(3)) { card in
                                CardView(
                                    card: card,
                                    isTopCard: true,
                                    offset: 0,
                                    scale: 0.7
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.l)
                    }
                }
            }
            
            Spacer()
            
            if !isSyncing {
                Button(action: onComplete) {
                    Text("Finish and go to Wallet")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            Task {
                await syncCards()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSyncing)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: foundCards.count)
    }
    
    private func syncCards() async {
        // Simulate progressive card discovery
        let allCards = await viewModel.syncCards()
        
        for (index, card) in allCards.enumerated() {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds between cards
            foundCards.append(card)
            syncProgress = Double(index + 1) / Double(allCards.count)
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        isSyncing = false
    }
}

