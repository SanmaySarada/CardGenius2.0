//
//  LocationManager.swift
//  CardGenius
//
//  Manages CoreLocation updates and permissions
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50 meters
        
        // Check current status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        print("[LocationManager] ===== REQUESTING LOCATION PERMISSION =====")
        print("[LocationManager] Current status before request: \(authorizationStatus.rawValue)")
        
        // Check if Info.plist has the required keys
        if let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") as? String {
            print("[LocationManager] Info.plist has NSLocationWhenInUseUsageDescription: \(usageDescription)")
        } else {
            print("[LocationManager] ERROR: NSLocationWhenInUseUsageDescription NOT FOUND in Info.plist!")
            print("[LocationManager] This will cause permission request to fail silently")
        }
        
        locationManager.requestWhenInUseAuthorization()
        print("[LocationManager] Permission request sent - waiting for user response...")
    }
    
    func startUpdatingLocation() {
        print("[LocationManager] ===== STARTING LOCATION UPDATES =====")
        print("[LocationManager] Current authorization status: \(authorizationStatus.rawValue)")
        print("[LocationManager] Status meanings: 0=notDetermined, 1=restricted, 2=denied, 3=authorizedAlways, 4=authorizedWhenInUse")
        
        // Force refresh authorization status from system
        let currentSystemStatus = locationManager.authorizationStatus
        if currentSystemStatus != authorizationStatus {
            print("[LocationManager] WARNING: Cached status (\(authorizationStatus.rawValue)) differs from system status (\(currentSystemStatus.rawValue))")
            authorizationStatus = currentSystemStatus
        }
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("[LocationManager] Location IS authorized - starting updates")
            locationManager.startUpdatingLocation()
            print("[LocationManager] Location updates started - waiting for actual location...")
            
            // Check if we already have a location
            if let currentLocation = userLocation {
                print("[LocationManager] Already have location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            } else {
                print("[LocationManager] No location yet - will update when CoreLocation provides it")
            }
        } else if authorizationStatus == .denied {
            print("[LocationManager] ERROR: Location permission was DENIED")
            print("[LocationManager] User must go to Settings > Privacy & Security > Location Services > CardGenius")
            print("[LocationManager] Cannot request permission again - user must enable in Settings")
        } else if authorizationStatus == .notDetermined {
            print("[LocationManager] Location permission NOT YET DETERMINED - requesting permission")
            requestPermission()
        } else {
            print("[LocationManager] Location status: \(authorizationStatus.rawValue) - requesting permission")
            requestPermission()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Debug function to check current location status
    func checkLocationStatus() {
        print("[LocationManager] ===== LOCATION STATUS CHECK =====")
        print("[LocationManager] Cached authorizationStatus: \(authorizationStatus.rawValue)")
        print("[LocationManager] System authorizationStatus: \(locationManager.authorizationStatus.rawValue)")
        print("[LocationManager] Has userLocation: \(userLocation != nil ? "YES" : "NO")")
        if let location = userLocation {
            print("[LocationManager] Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        print("[LocationManager] Location services enabled: \(CLLocationManager.locationServicesEnabled())")
        print("[LocationManager] ===== END STATUS CHECK =====")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("[LocationManager] ERROR: Received empty locations array")
            return
        }
        // STRICT: Only store actual location coordinates - no defaults
        
        // Log location details for debugging
        print("[LocationManager] ===== LOCATION UPDATE RECEIVED =====")
        print("[LocationManager] New location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("[LocationManager] Accuracy: ±\(location.horizontalAccuracy)m")
        print("[LocationManager] Timestamp: \(location.timestamp)")
        
        // Check if this is significantly different from previous location
        if let previousLocation = userLocation {
            let distance = location.distance(from: previousLocation)
            print("[LocationManager] Distance from previous: \(Int(distance))m")
        } else {
            print("[LocationManager] This is the FIRST location update")
        }
        
        userLocation = location
        print("[LocationManager] Location stored successfully")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
        locationError = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus
        
        print("[LocationManager] ===== AUTHORIZATION STATUS CHANGED =====")
        print("[LocationManager] Old status: \(oldStatus.rawValue) -> New status: \(authorizationStatus.rawValue)")
        print("[LocationManager] Status meanings: 0=notDetermined, 1=restricted, 2=denied, 3=authorizedAlways, 4=authorizedWhenInUse")
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("[LocationManager] Location AUTHORIZED - starting location updates")
            manager.startUpdatingLocation()
        } else if authorizationStatus == .denied {
            print("[LocationManager] ERROR: Location access DENIED by user")
            print("[LocationManager] User must enable location in Settings > Privacy & Security > Location Services")
        } else if authorizationStatus == .restricted {
            print("[LocationManager] ERROR: Location access RESTRICTED (parental controls?)")
        } else if authorizationStatus == .notDetermined {
            print("[LocationManager] Location permission not yet determined - waiting for user response")
        }
    }
}
