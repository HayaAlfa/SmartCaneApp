//
//  LocationManager.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 8/30/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var locationError: String?
    @Published var isFollowingUser = true
    @Published var locationAccuracy: CLLocationAccuracy = 0.0
    @Published var lastLocationUpdate: Date?
    @Published var userHeading: CLLocationDirection = 0.0
    @Published var isHeadingEnabled = false
    
    private var manager = CLLocationManager()
    private var locationUpdateTimer: Timer?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3.0 // Update location every 3 meters for better tracking
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = false
        manager.activityType = .fitness // Optimized for walking/movement
        
        // Enable heading updates for direction tracking
        manager.headingFilter = 5.0 // Update heading every 5 degrees
        manager.headingOrientation = .portrait // Default orientation
        
        // Check current authorization status
        authorizationStatus = manager.authorizationStatus
        
        // Request permission if not determined
        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    func requestLocationPermission() {
        print("📍 Requesting location permission...")
        manager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Location permission not granted")
            locationError = "Location permission required"
            return
        }
        
        // Check location services on background queue to avoid blocking main thread
        DispatchQueue.global(qos: .userInitiated).async {
            guard CLLocationManager.locationServicesEnabled() else {
                DispatchQueue.main.async {
                    print("❌ Location services disabled")
                    self.locationError = "Location services are disabled. Please enable in Settings."
                }
                return
            }
            
            DispatchQueue.main.async {
                print("📍 Starting location and heading updates...")
                self.manager.startUpdatingLocation()
                self.manager.startUpdatingHeading()
                self.isLocationEnabled = true
                self.isHeadingEnabled = true
                self.locationError = nil
                
                // Start a timer to monitor location updates
                self.startLocationUpdateTimer()
            }
        }
    }
    
    func stopLocationUpdates() {
        print("📍 Stopping location and heading updates...")
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isLocationEnabled = false
        isHeadingEnabled = false
        stopLocationUpdateTimer()
    }
    
    private func startLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkLocationUpdateStatus()
        }
    }
    
    private func stopLocationUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    private func checkLocationUpdateStatus() {
        guard let lastUpdate = lastLocationUpdate else {
            print("⚠️ No location updates received yet")
            return
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > 60.0 { // No updates for more than 1 minute
            locationError = "Location updates may be delayed"
        }
    }
    
    func centerOnUserLocation() {
        guard let location = currentLocation else {
            print("❌ No current location available")
            locationError = "No location available. Please wait for GPS signal."
            return
        }
        
        DispatchQueue.main.async {
            self.region.center = location.coordinate
            print("📍 Centered map on user location: \(location.coordinate)")
        }
    }
    
    func followUserLocation() {
        isFollowingUser = true
        print("📍 Following user location")
    }
    
    func stopFollowingUser() {
        isFollowingUser = false
        print("📍 Stopped following user location")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out low accuracy locations
        if location.horizontalAccuracy > 100 { // Relaxed accuracy filter for debugging
            print("⚠️ Low accuracy location received: \(location.horizontalAccuracy)m")
            return
        }
        
        print("📍 Location received: \(location.coordinate), accuracy: \(location.horizontalAccuracy)m")
        
        // Check if this is a significant location change
        if let previousLocation = currentLocation {
            let distance = location.distance(from: previousLocation)
            if distance < 2.0 { // Less than 2 meters, might be noise
                print("📍 Location change too small: \(distance)m")
                return
            }
        }
        
        DispatchQueue.main.async {
            print("📍 Setting currentLocation to: \(location.coordinate)")
            self.currentLocation = location
            self.locationAccuracy = location.horizontalAccuracy
            self.lastLocationUpdate = Date()
            self.locationError = nil
            
            // Update map region smoothly if following user
            if self.isFollowingUser {
                let newRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: self.region.span
                )
                self.region = newRegion
            }
            
            print("📍 Location updated: \(location.coordinate) (accuracy: \(location.horizontalAccuracy)m)")
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Location permission granted")
                self.locationError = nil
                self.startLocationUpdates()
                
            case .denied, .restricted:
                print("❌ Location permission denied")
                self.locationError = "Location access denied. Please enable in Settings."
                self.isLocationEnabled = false
                self.stopLocationUpdates()
                
            case .notDetermined:
                print("⏳ Location permission not determined")
                self.locationError = "Location permission required"
                self.isLocationEnabled = false
                
            @unknown default:
                print("❓ Unknown authorization status")
                self.locationError = "Unknown location permission status"
                self.isLocationEnabled = false
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // This is called on iOS 14+ when authorization changes
        let status = manager.authorizationStatus
        locationManager(manager, didChangeAuthorization: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Filter out low accuracy headings
        guard newHeading.headingAccuracy >= 0 else {
            print("⚠️ Low accuracy heading received: \(newHeading.headingAccuracy)")
            return
        }
        
        DispatchQueue.main.async {
            self.userHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            // print("🧭 Heading updated: \(Int(self.userHeading))° (accuracy: \(newHeading.headingAccuracy)°)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
            self.isLocationEnabled = false
            self.isHeadingEnabled = false
            print("❌ Location/Heading error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Utility Methods
    
    func getCurrentLocationString() -> String {
        guard let location = currentLocation else {
            return "Location not available"
        }
        
        return String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    func getLocationAccuracy() -> String {
        guard let location = currentLocation else {
            return "N/A"
        }
        
        return String(format: "%.1fm", location.horizontalAccuracy)
    }
    
    func getLastUpdateTime() -> String {
        guard let lastUpdate = lastLocationUpdate else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: lastUpdate)
    }
    
    func getCurrentHeading() -> String {
        return String(format: "%.0f°", userHeading)
    }
    
    func getHeadingDirection() -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((userHeading + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    func getFullHeadingInfo() -> String {
        return "\(getCurrentHeading()) \(getHeadingDirection())"
    }
    
    func isLocationServiceEnabled() -> Bool {
        // Note: This method can block the main thread, so use it sparingly
        // Consider using the delegate callbacks instead for better performance
        return CLLocationManager.locationServicesEnabled()
    }
    
    func getLocationStatusDescription() -> String {
        // Use authorization status to infer location services state
        // This avoids calling CLLocationManager.locationServicesEnabled() which can block main thread
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if isLocationEnabled {
                return "Tracking active"
            } else {
                return "Ready to track"
            }
        case .denied, .restricted:
            return "Access denied"
        case .notDetermined:
            return "Permission needed"
        @unknown default:
            return "Unknown status"
        }
    }
}

