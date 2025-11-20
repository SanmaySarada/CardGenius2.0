//
//  OnboardingViewModel.swift
//  CardGenius
//
//  Onboarding View Model
//

import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var institutions: [Institution] = []
    @Published var cards: [Card] = []
    
    var institutionService: InstitutionServiceProtocol
    var cardService: CardServiceProtocol
    
    init(
        institutionService: InstitutionServiceProtocol,
        cardService: CardServiceProtocol
    ) {
        self.institutionService = institutionService
        self.cardService = cardService
    }
    
    var selectedInstitutions: [Institution] {
        institutions.filter { $0.isSelected }
    }
    
    var allInstitutionsLinked: Bool {
        selectedInstitutions.allSatisfy { $0.connectionStatus == .linked }
    }
    
    func loadInstitutions() async {
        do {
            institutions = try await institutionService.fetchSupportedInstitutions()
        } catch {
            // Handle error
            print("Error loading institutions: \(error)")
        }
    }
    
    func toggleInstitution(_ institution: Institution) {
        if let index = institutions.firstIndex(where: { $0.id == institution.id }) {
            institutions[index].isSelected.toggle()
        }
    }
    
    func linkInstitution(_ institution: Institution) async {
        guard let index = institutions.firstIndex(where: { $0.id == institution.id }) else { return }
        
        institutions[index].connectionStatus = .linking
        
        do {
            try await institutionService.linkInstitution(institution)
            institutions[index].connectionStatus = .linked
        } catch {
            institutions[index].connectionStatus = .error
        }
    }
    
    func syncCards() async -> [Card] {
        do {
            cards = try await cardService.fetchCards()
            return cards
        } catch {
            return []
        }
    }
}

