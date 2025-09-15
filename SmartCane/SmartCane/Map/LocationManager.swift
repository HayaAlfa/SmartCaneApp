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
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            locationError = "Location services are disabled. Please enable in Settings."
            return
        }
        
        print("📍 Starting location updates...")
        manager.startUpdatingLocation()
        isLocationEnabled = true
        locationError = nil
        
        // Start a timer to monitor location updates
        startLocationUpdateTimer()
    }
    
    func stopLocationUpdates() {
        print("📍 Stopping location updates...")
        manager.stopUpdatingLocation()
        isLocationEnabled = false
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
            print("⚠️ No location updates for \(Int(timeSinceLastUpdate)) seconds")
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
        if location.horizontalAccuracy > 50 { // More strict accuracy filter
            print("⚠️ Low accuracy location received: \(location.horizontalAccuracy)m")
            return
        }
        
        // Check if this is a significant location change
        if let previousLocation = currentLocation {
            let distance = location.distance(from: previousLocation)
            if distance < 2.0 { // Less than 2 meters, might be noise
                print("📍 Location change too small: \(distance)m")
                return
            }
        }
        
        DispatchQueue.main.async {
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
            self.isLocationEnabled = false
            print("❌ Location error: \(error.localizedDescription)")
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
    
    func isLocationServiceEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    func getLocationStatusDescription() -> String {
        if !isLocationServiceEnabled() {
            return "Location services disabled"
        }
        
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

