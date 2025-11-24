//
//  MerchantService.swift
//  CardGenius
//
//  Real Merchant Service Implementation
//

import Foundation
import CoreLocation

class MerchantService: MerchantServiceProtocol {
    private let locationManager: LocationManager
    private let cardService: CardServiceProtocol
    
    init(locationManager: LocationManager, cardService: CardServiceProtocol) {
        self.locationManager = locationManager
        self.cardService = cardService
    }
    
    func getCurrentMerchant() async throws -> Merchant? {
        // STRICT: Only use actual location from LocationManager - NO fallback coordinates
        guard let location = locationManager.userLocation else {
            print("[MerchantService] ERROR: No actual user location available - cannot proceed without real coordinates")
            return nil
        }
        
        print("[MerchantService] Using actual location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Fetch nearby places from Google Places API
        let places = try await fetchNearbyPlaces(location: location)
        
        print("[MerchantService] Found \(places.count) places nearby")
        
        // Return the closest one (sorted by distance)
        if let closestPlace = places.first {
            let merchant = mapPlaceToMerchant(closestPlace)
            print("[MerchantService] Selected closest merchant: \(merchant.name) at distance: \(calculateDistance(from: location, to: CLLocation(latitude: closestPlace.geometry.location.lat, longitude: closestPlace.geometry.location.lng)))m")
            return merchant
        }
        
        print("[MerchantService] No places found nearby")
        return nil
    }
    
    func getNearbyMerchants() async throws -> [Merchant] {
        // STRICT: Only use actual location from LocationManager - NO fallback coordinates
        guard let location = locationManager.userLocation else {
            print("[MerchantService] ERROR: No actual user location available - cannot fetch nearby merchants without real coordinates")
            return []
        }
        
        let places = try await fetchNearbyPlaces(location: location)
        return places.compactMap { mapPlaceToMerchant($0) }
    }
    
    func getRecommendedCard(for merchant: Merchant) async throws -> Card? {
        print("[MerchantService] ===== Getting recommended card based on ACTUAL LOCATION =====")
        print("[MerchantService] Merchant: \(merchant.name)")
        print("[MerchantService] Merchant location: \(merchant.location.latitude), \(merchant.location.longitude)")
        print("[MerchantService] Merchant category: \(merchant.category.rawValue)")
        print("[MerchantService] Merchant types: \(merchant.rawTypes ?? [])")
        
        // Global Search Mode: Search ALL cards in the CSV
        let rewardsMatrix = CSVParser.shared.parseRewardsMatrix()
        
        if rewardsMatrix.isEmpty {
            print("[MerchantService] Warning: Rewards matrix is empty")
        } else {
            print("[MerchantService] Searching through \(rewardsMatrix.count) cards in rewards matrix")
        }
        
        // Get all CSV column names (categories) for search term building
        let allCategories = getAllCategories(from: rewardsMatrix)
        
        // Build search terms from mapped category (like Python's build_search_terms)
        let categoryName = merchant.category.rawValue
        let searchTerms = buildSearchTerms(category: categoryName, availableCategories: allCategories)
        
        print("[MerchantService] Search terms for category '\(categoryName)': \(searchTerms)")
        
        var bestCardName: String?
        var maxReward = -1.0
        var bestMatchingStrategy: String = "None"
        var bestMatchedCategory: String?
        
        // Iterate through ALL cards in the matrix (SILENTLY - no per-card logging)
        for (cardName, rewards) in rewardsMatrix {
            let (reward, strategy, category) = getBestReward(for: merchant, in: rewards, searchTerms: searchTerms)
            
            if reward > maxReward {
                maxReward = reward
                bestCardName = cardName
                bestMatchingStrategy = strategy
                bestMatchedCategory = category
            }
        }
        
        // Log ONCE per merchant after finding best card
        if let bestName = bestCardName, maxReward > 0 {
            print("[MerchantService] ===== RECOMMENDATION RESULT =====")
            print("[MerchantService] Best card: \(bestName)")
            print("[MerchantService] Reward rate: \(maxReward)%")
            if let category = bestMatchedCategory {
                print("[MerchantService] Matched category: '\(category)' using strategy: \(bestMatchingStrategy)")
            }
            print("[MerchantService] Based on merchant at ACTUAL LOCATION: \(merchant.location.latitude), \(merchant.location.longitude)")
            
            // Create a temporary card object for the recommendation
            // We try to find it in the user's wallet first to get real details
            let cards = try await cardService.fetchCards()
            if let existingCard = cards.first(where: { $0.displayName == bestName }) {
                print("[MerchantService] Found existing card in wallet: \(existingCard.displayName)")
                return existingCard
            }
            
            // Otherwise, create a transient card
            print("[MerchantService] Creating transient card recommendation")
            return Card(
                id: UUID().uuidString,
                issuer: bestName, // Use name as issuer
                nickname: "Recommended",
                last4: "----",
                network: .visa, // Placeholder
                cardType: .credit,
                cardStyle: .blue, // Placeholder
                status: .active,
                imageName: nil,
                rewardCategories: [
                    RewardCategory(
                        id: UUID().uuidString,
                        name: "Best Match",
                        multiplier: maxReward,
                        description: String(format: "%.1f%% back at %@", maxReward, merchant.name)
                    )
                ],
                creditLimit: nil,
                currentBalance: nil,
                currentMonthSpend: 0.0,
                isIncludedInOptimization: true,
                routingPriority: 1.0,
                institutionId: "global-recommendation"
            )
        } else if maxReward == 0 {
            // Only warn if NO match found at all (including fallbacks)
            print("[MerchantService] WARNING: No reward match found for merchant '\(merchant.name)' - no cards offer rewards for this category")
        }
        
        print("[MerchantService] No card recommendation found")
        return nil
    }
    
    // MARK: - Helpers
    
    /// Builds search terms from category (ported from Python's build_search_terms)
    /// Strategy: include category itself + any CSV columns containing category as substring + fallbacks
    private func buildSearchTerms(category: String, availableCategories: [String]) -> [String] {
        var terms: [String] = []
        let normalized = category.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !normalized.isEmpty {
            // Add the category itself
            terms.append(normalized)
            
            // Find all CSV columns that contain the category as a substring
            let categoryLower = normalized.lowercased()
            for csvCategory in availableCategories {
                if csvCategory.lowercased().contains(categoryLower) {
                    terms.append(csvCategory)
                }
            }
        }
        
        // Add generic fallbacks (like Python's DEFAULT_FALLBACK_TERMS)
        terms.append("Everywhere")
        terms.append("Other purchases")
        
        // Deduplicate while preserving order (like Python)
        var seen = Set<String>()
        var deduplicated: [String] = []
        for term in terms {
            let termLower = term.lowercased()
            if !seen.contains(termLower) {
                seen.insert(termLower)
                deduplicated.append(term)
            }
        }
        
        return deduplicated
    }
    
    /// Gets all unique category names from the rewards matrix (CSV columns)
    private func getAllCategories(from rewardsMatrix: [String: [String: Double]]) -> [String] {
        var categories = Set<String>()
        for (_, rewards) in rewardsMatrix {
            for category in rewards.keys {
                categories.insert(category)
            }
        }
        return Array(categories).sorted()
    }
    
    /// Gets the best reward for a merchant using search terms (matches Python logic)
    /// Returns: (reward, matchingStrategy, matchedCategory)
    /// SILENT: No logging here - called for every card, so logging happens once in getRecommendedCard()
    private func getBestReward(for merchant: Merchant, in rewards: [String: Double], searchTerms: [String]) -> (Double, String, String?) {
        var maxVal = 0.0
        var matchedCategory: String?
        var matchingStrategy: String = "None"
        
        // 1. Check Merchant Name (e.g., "H-E-B", "Target") - direct brand matching
        let merchantNameLower = merchant.name.lowercased()
        for (key, val) in rewards {
            if merchantNameLower.contains(key.lowercased()) && key.count > 3 {
                if val > maxVal {
                    maxVal = val
                    matchedCategory = key
                    matchingStrategy = "Merchant Name Match"
                }
            }
        }
        
        // 2. Check Raw Google Types (e.g., "supermarket", "drugstore")
        if let types = merchant.rawTypes {
            for type in types {
                // Check exact match for type in CSV
                if let val = rewards[type] {
                    if val > maxVal {
                        maxVal = val
                        matchedCategory = type
                        matchingStrategy = "Google Type Exact Match"
                    }
                }
                // Check partial match
                for (key, val) in rewards {
                    if key.lowercased().contains(type.lowercased()) {
                        if val > maxVal {
                            maxVal = val
                            matchedCategory = key
                            matchingStrategy = "Google Type Partial Match"
                        }
                    }
                }
            }
        }
        
        // 3. Check search terms (like Python's candidate_columns matching)
        // This is the key difference - Python uses search terms to find matching CSV columns
        for searchTerm in searchTerms {
            let searchTermLower = searchTerm.lowercased()
            
            // Check exact match
            if let val = rewards[searchTerm] {
                if val > maxVal {
                    maxVal = val
                    matchedCategory = searchTerm
                    matchingStrategy = "Search Term Exact Match"
                }
            }
            
            // Check if any CSV column contains the search term (or vice versa)
            for (csvCategory, val) in rewards {
                let csvCategoryLower = csvCategory.lowercased()
                // Match if search term is in CSV category OR CSV category is in search term
                if csvCategoryLower.contains(searchTermLower) || searchTermLower.contains(csvCategoryLower) {
                    if val > maxVal {
                        maxVal = val
                        matchedCategory = csvCategory
                        matchingStrategy = "Search Term Partial Match"
                    }
                }
            }
        }
        
        // 4. Fallback (should already be covered by search terms, but keep for safety)
        let fallback = rewards["Everywhere"] ?? rewards["Other purchases"] ?? 0.0
        if fallback > maxVal {
            maxVal = fallback
            matchedCategory = rewards["Everywhere"] != nil ? "Everywhere" : "Other purchases"
            matchingStrategy = "Fallback Category"
        }
        
        // NO LOGGING HERE - this function is called for every card (499 times!)
        // Logging happens once in getRecommendedCard() after finding the best card
        return (maxVal, matchingStrategy, matchedCategory)
    }
    
    private struct GooglePlace: Decodable {
        let name: String
        let place_id: String
        let vicinity: String?
        let types: [String]?
        let geometry: Geometry
        
        struct Geometry: Decodable {
            let location: Location
            struct Location: Decodable {
                let lat: Double
                let lng: Double
            }
        }
    }
    
    private struct PlacesResponse: Decodable {
        let results: [GooglePlace]
        let status: String
        let error_message: String?
    }
    
    private func fetchNearbyPlaces(location: CLLocation) async throws -> [GooglePlace] {
        // STRICT: This function ONLY accepts actual location coordinates - no defaults
        let apiKey = Configuration.googlePlacesApiKey
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let radius = 50 // Reduced from 100m for better precision
        
        print("[MerchantService] Fetching places using actual coordinates: \(lat), \(lng)")
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("[MerchantService] Error: Invalid URL for Google Places API")
            return []
        }
        
        print("[MerchantService] Fetching places from Google Places API...")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("[MerchantService] HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("[MerchantService] Error: HTTP \(httpResponse.statusCode)")
                    return []
                }
            }
            
            let placesResponse = try JSONDecoder().decode(PlacesResponse.self, from: data)
            
            // Check API status
            if placesResponse.status != "OK" {
                print("[MerchantService] Google Places API Error: \(placesResponse.status)")
                if let errorMessage = placesResponse.error_message {
                    print("[MerchantService] Error message: \(errorMessage)")
                }
                
                // Handle specific error cases
                switch placesResponse.status {
                case "OVER_QUERY_LIMIT":
                    print("[MerchantService] API quota exceeded")
                case "REQUEST_DENIED":
                    print("[MerchantService] API request denied - check API key")
                case "INVALID_REQUEST":
                    print("[MerchantService] Invalid request parameters")
                default:
                    break
                }
                return []
            }
            
            // Sort results by distance (closest first)
            let sortedPlaces = placesResponse.results.sorted { place1, place2 in
                let distance1 = calculateDistance(
                    from: location,
                    to: CLLocation(latitude: place1.geometry.location.lat, longitude: place1.geometry.location.lng)
                )
                let distance2 = calculateDistance(
                    from: location,
                    to: CLLocation(latitude: place2.geometry.location.lat, longitude: place2.geometry.location.lng)
                )
                return distance1 < distance2
            }
            
            print("[MerchantService] Successfully fetched \(sortedPlaces.count) places, sorted by distance")
            
            return sortedPlaces
        } catch {
            print("[MerchantService] Error fetching places: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Calculate distance between two locations in meters
    private func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to)
    }
    
    private func mapPlaceToMerchant(_ place: GooglePlace) -> Merchant {
        let categoryName = CategoryMapper.shared.mapPlaceToCategory(name: place.name, types: place.types)
        
        print("[MerchantService] Mapped '\(place.name)' with types \(place.types ?? []) to category: \(categoryName)")
        
        // Map string category to MerchantCategory enum
        let category = MerchantCategory(rawValue: categoryName) ?? .other
        
        return Merchant(
            id: place.place_id,
            name: place.name,
            category: category,
            rawTypes: place.types, // Store raw types
            address: place.vicinity ?? "",
            location: Merchant.Location(
                latitude: place.geometry.location.lat,
                longitude: place.geometry.location.lng
            ),
            iconName: category.iconName
        )
    }
}
