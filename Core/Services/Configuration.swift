//
//  Configuration.swift
//  CardGenius
//
//  App Configuration
//

import Foundation

struct Configuration {
    // TODO: Replace with your actual API Key or ensure it's in Info.plist
    static var googlePlacesApiKey: String {
        // Try to read from Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String, !key.isEmpty {
            return key
        }
        // Fallback to hardcoded key
        return "AIzaSyCuQsZ28OaiqCMCVpWH6DWnBuRvoRK8kuw"
    }
}
