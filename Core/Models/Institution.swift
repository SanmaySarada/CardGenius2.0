//
//  Institution.swift
//  CardGenius
//
//  Institution Model
//

import Foundation

struct Institution: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoAssetName: String?
    let description: String
    var isSelected: Bool
    var connectionStatus: ConnectionStatus
    
    enum ConnectionStatus: String, Codable {
        case notLinked = "Not linked"
        case linking = "Linking…"
        case linked = "Linked"
        case error = "Error"
    }
}

