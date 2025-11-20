//
//  InstitutionServiceProtocol.swift
//  CardGenius
//
//  Institution Service Protocol
//

import Foundation

protocol InstitutionServiceProtocol {
    func fetchSupportedInstitutions() async throws -> [Institution]
    func linkInstitution(_ institution: Institution) async throws -> Void
    func unlinkInstitution(_ institution: Institution) async throws -> Void
    func getLinkedInstitutions() async throws -> [Institution]
}

