//
//  Merchant.swift
//  CardGenius
//
//  Merchant Model
//

import Foundation
import CoreLocation

struct Merchant: Identifiable, Codable {
    let id: String
    let name: String
    let category: MerchantCategory
    let address: String
    let location: Location
    let iconName: String?
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

enum MerchantCategory: String, Codable {
    case dining = "Dining"
    case groceries = "Groceries"
    case gas = "Gas"
    case travel = "Travel"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .gas: return "fuelpump.fill"
        case .travel: return "airplane"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .other: return "storefront.fill"
        }
    }
}

