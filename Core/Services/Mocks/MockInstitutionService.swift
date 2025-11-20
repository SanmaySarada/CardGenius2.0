//
//  MockInstitutionService.swift
//  CardGenius
//
//  Mock Institution Service Implementation
//

import Foundation

class MockInstitutionService: InstitutionServiceProtocol {
    private var institutions: [Institution] = []
    
    init() {
        institutions = MockData.sampleInstitutions
    }
    
    func fetchSupportedInstitutions() async throws -> [Institution] {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        return institutions
    }
    
    func linkInstitution(_ institution: Institution) async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds to simulate linking
        
        if let index = institutions.firstIndex(where: { $0.id == institution.id }) {
            institutions[index].connectionStatus = .linked
        }
    }
    
    func unlinkInstitution(_ institution: Institution) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let index = institutions.firstIndex(where: { $0.id == institution.id }) {
            institutions[index].connectionStatus = .notLinked
        }
    }
    
    func getLinkedInstitutions() async throws -> [Institution] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return institutions.filter { $0.connectionStatus == .linked }
    }
}

