//
//  CategoryMapper.swift
//  CardGenius
//
//  Maps place names and types to reward categories.
//  Ported from map_to_category.py
//

import Foundation

class CategoryMapper {
    static let shared = CategoryMapper()
    
    private init() {}
    
    // MARK: - Data
    
    private let categories: [String] = [
        "AAA", "AT&T", "Alaska Air", "Amazon", "Amtrak", "Athleta", "Banana Republic",
        "Barnes & Noble", "Bass Pro", "Beauty", "Bed Bath & Beyond", "Belk", "Bloomingdale",
        "Book Store", "British Air", "Bus", "Car Rental", "Choice", "Costco Gas", "Cruise",
        "Department Stores", "Dining", "Drugstore", "Electronics retailers (up to $2M spend/yr)",
        "Entertainment", "Fast Food", "Flights (Amex Travel)", "Food Delivery", "Gas",
        "Gas stations (U.S.)", "Grocery", "Grocery stores (U.S.)", "Gym", "Hilton hotels/resorts",
        "Home Improvement", "Hotel", "IHG", "JCPenney", "Kohl's", "Kroger", "Lowe's", "Lyft",
        "Macy's", "Marriott", "Marshalls", "Menards", "Old Navy", "Online retail (U.S.)",
        "Other purchases", "REI", "Restaurants", "Ride-Sharing", "Sam's Club", "Sporting Good",
        "Starbucks", "Streaming services", "Supermarkets (U.S.)", "TJ Maxx", "Target",
        "Telecommunication", "Transit", "Travel", "Walgreens", "Wayfair", "Whole Foods",
        "Wholesale Club", "Wireless telephone services (direct, U.S. providers)"
    ]
    
    private let brandOverrides: [String: String] = [
        "target": "Target",
        "walmart": "Department Stores",
        "costco": "Wholesale Club",
        "sam's club": "Wholesale Club",
        "sams club": "Wholesale Club",
        "bjs": "Wholesale Club",
        "whole foods": "Whole Foods",
        "trader joe": "Grocery",
        "ralphs": "Grocery",
        "starbucks": "Starbucks",
        "mcdonald": "Fast Food",
        "in n out": "Fast Food",
        "chipotle": "Dining",
        "panera": "Dining",
        "shell": "Gas stations (U.S.)",
        "chevron": "Gas stations (U.S.)",
        "hilton": "Hilton hotels/resorts",
        "marriott": "Marriott",
        "hyatt": "Hotel",
        "ihg": "IHG",
        "aaa": "AAA",
        "at&t": "AT&T",
        "att": "AT&T",
        "old navy": "Old Navy",
        "marshalls": "Marshalls",
        "athleta": "Athleta",
        "banana republic": "Banana Republic",
        "barnes & noble": "Barnes & Noble",
        "barnes and noble": "Barnes & Noble",
        "bass pro": "Bass Pro",
        "belk": "Belk",
        "bloomingdale": "Bloomingdale",
        "choice": "Choice",
        "jcpenney": "JCPenney",
        "jcpenny": "JCPenney",
        "kohl's": "Kohl's",
        "kohls": "Kohl's",
        "kroger": "Kroger",
        "lowe's": "Lowe's",
        "lowes": "Lowe's",
        "lyft": "Lyft",
        "macy's": "Macy's",
        "macys": "Macy's",
        "menards": "Menards",
        "rei": "REI",
        "tj maxx": "TJ Maxx",
        "walgreens": "Walgreens",
        "wayfair": "Wayfair"
    ]
    
    // Normalized brand overrides for better matching (like Python's _NORMALIZED_BRAND_OVERRIDES)
    private lazy var normalizedBrandOverrides: [String: String] = {
        var normalized: [String: String] = [:]
        for (brand, category) in brandOverrides {
            let normalizedBrand = normalizeText(brand)
            normalized[normalizedBrand] = category
        }
        return normalized
    }()
    
    private let typeToCategory: [String: String] = [
        // Food / dining
        "restaurant": "Restaurants",
        "cafe": "Dining",
        "bar": "Dining",
        "meal_takeaway": "Takeout/Delivery (U.S.)",
        "meal_delivery": "Food Delivery",
        "bakery": "Dining",
        "fast_food_restaurant": "Fast Food",
        "food": "Dining",
        
        // Retail / shopping
        "supermarket": "Supermarkets (U.S.)",
        "grocery_or_supermarket": "Grocery",
        "convenience_store": "Grocery",
        "department_store": "Department Stores",
        "clothing_store": "Department Stores",
        "shopping_mall": "Department Stores",
        "electronics_store": "Electronics retailers (up to $2M spend/yr)",
        "home_goods_store": "Home Improvement",
        "hardware_store": "Home Improvement",
        "furniture_store": "Home Improvement",
        "book_store": "Book Store",
        "pharmacy": "Drugstore",
        "store": "Department Stores",
        
        // Travel & transport
        "gas_station": "Gas stations (U.S.)",
        "lodging": "Hotel",
        "hotel": "Hotel",
        "car_rental": "Car Rental",
        "bus_station": "Transit",
        "train_station": "Transit",
        "subway_station": "Transit",
        "airport": "Travel",
        
        // Entertainment & recreation
        "gym": "Gym",
        "movie_theater": "Entertainment",
        "amusement_park": "Entertainment",
        "stadium": "Entertainment",
        "museum": "Entertainment",
        "night_club": "Entertainment",
        "spa": "Beauty"
    ]
    
    // MARK: - Logic
    
    func mapPlaceToCategory(name: String?, types: [String]?) -> String {
        let placeName = name ?? ""
        let placeTypes = types ?? []
        
        let nameLower = placeName.lowercased()
        let nameNorm = normalizeText(placeName)
        
        print("[CategoryMapper] Mapping place: '\(placeName)' with types: \(placeTypes)")
        
        // 1. Check brand overrides (normalized matching first, then raw)
        // First try normalized containment to absorb punctuation/spacing variants
        for (brandNorm, cat) in normalizedBrandOverrides {
            if !brandNorm.isEmpty && nameNorm.contains(brandNorm) {
                print("[CategoryMapper] Matched brand override (normalized): '\(brandNorm)' -> \(cat)")
                return cat
            }
        }
        // Fallback to legacy lowercase substring (covers simple cases)
        for (brand, cat) in brandOverrides {
            if nameLower.contains(brand) {
                print("[CategoryMapper] Matched brand override (raw): '\(brand)' -> \(cat)")
                return cat
            }
        }
        
        // 2. Check explicit type mappings (check ALL types, not just first)
        for type in placeTypes {
            if let cat = typeToCategory[type] {
                print("[CategoryMapper] Matched type: '\(type)' -> \(cat)")
                return cat
            }
        }
        
        // 3. Fuzzy match (Simplified: Contains check)
        // Swift doesn't have Python's difflib.get_close_matches built-in.
        // We'll do a simple containment check
        for cat in categories {
            if nameLower.contains(cat.lowercased()) {
                print("[CategoryMapper] Matched category (fuzzy): '\(cat)'")
                return cat
            }
        }
        
        // 4. Default
        print("[CategoryMapper] No match found, using default: 'Other purchases'")
        return "Other purchases"
    }
    
    private func normalizeText(_ text: String) -> String {
        // Match Python's _normalize_text function
        let lower = text.lowercased()
        let noAmp = lower.replacingOccurrences(of: "&", with: "")
        // Remove all non-alphanumeric characters (like Python's _NON_ALNUM_RE.sub)
        let allowed = CharacterSet.alphanumerics
        return noAmp.components(separatedBy: allowed.inverted).joined()
    }
}
