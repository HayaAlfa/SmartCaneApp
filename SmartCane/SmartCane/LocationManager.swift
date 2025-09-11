<<<<<<< HEAD
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
=======
import SwiftUI
import CoreLocation  // Apple's location framework for GPS and location services
import MapKit       // Apple's mapping framework for coordinate regions

// MARK: - Location Manager Class
// This class manages all location-related functionality including GPS tracking, permissions, and location updates
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    // These properties automatically update the UI when they change
    @Published var currentLocation: CLLocation? = nil           // Current GPS coordinates
    @Published var region = MKCoordinateRegion(                 // Map view region (center and zoom level)
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),  // Default: San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)         // Zoom level
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined  // Location permission status
    @Published var locationError: String? = nil                 // Error messages for location issues
    @Published var isLocationEnabled = false                     // Whether location services are active
    @Published var isFollowingUser = false                      // Whether map should follow user movement
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()            // Core Location manager instance
    private var lastUpdateTime = Date()                          // When location was last updated
    private var locationAccuracy: CLLocationAccuracy = 0.0      // GPS accuracy in meters
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()  // Configure location manager when class is created
    }
    
    // MARK: - Location Manager Setup
    // Configures the Core Location manager with proper settings
    private func setupLocationManager() {
        locationManager.delegate = self                    // Set this class as the delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // Request highest GPS accuracy
        locationManager.distanceFilter = 5.0               // Update location every 5 meters of movement
        locationManager.allowsBackgroundLocationUpdates = false     // Don't track location when app is in background
        
        print("📍 LocationManager initialized with best accuracy")
    }
    
    // MARK: - Location Permission Management
    
    // Request location permission from user
    func requestLocationPermission() {
        print("🔐 Requesting location permission...")
        
        switch authorizationStatus {
        case .notDetermined:
            // First time using app - request permission
            locationManager.requestWhenInUseAuthorization()
            print("📱 Requesting 'When In Use' authorization")
            
        case .denied, .restricted:
            // User denied permission - show settings alert
            locationError = "Location access denied. Please enable in Settings."
            print("❌ Location access denied by user")
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission already granted - start location updates
            startLocationUpdates()
            print("✅ Location permission already granted")
            
        @unknown default:
            // Handle future iOS versions
            locationManager.requestWhenInUseAuthorization()
            print("🔮 Unknown authorization status - requesting permission")
        }
    }
    
    // Start receiving location updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Cannot start location updates - no permission")
            return
        }
        
        print("🚀 Starting location updates...")
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    // Stop receiving location updates
    func stopLocationUpdates() {
        print("⏹️ Stopping location updates...")
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    // MARK: - Map Control Functions
    
    // Center the map on the user's current location
    func centerOnUserLocation() {
        guard let location = currentLocation else {
            print("❌ Cannot center map - no current location")
            return
        }
        
        print("🎯 Centering map on user location: \(location.coordinate)")
        
        // Animate map movement to user location
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // Make the map follow the user as they move
    func followUserLocation() {
        print("👥 Enabling user location following")
        isFollowingUser = true
        
        // Start location updates if not already running
        if !isLocationEnabled {
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
            startLocationUpdates()
        }
    }
    
<<<<<<< HEAD
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
=======
    // Stop the map from following the user
    func stopFollowingUser() {
        print("🚫 Disabling user location following")
        isFollowingUser = false
    }
    
    // MARK: - Location Information Getters
    
    // Get a human-readable description of location status
    func getLocationStatusDescription() -> String {
        switch authorizationStatus {
        case .notDetermined:
            return "Permission not determined"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        case .authorizedWhenInUse:
            return isLocationEnabled ? "Active (When in use)" : "Inactive"
        case .authorizedAlways:
            return isLocationEnabled ? "Active (Always)" : "Inactive"
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
        @unknown default:
            return "Unknown status"
        }
    }
<<<<<<< HEAD
}

=======
    
    // Get GPS accuracy as a human-readable string
    func getLocationAccuracy() -> String {
        if locationAccuracy == 0.0 {
            return "Unknown"
        } else if locationAccuracy < 5.0 {
            return "Excellent (< 5m)"
        } else if locationAccuracy < 10.0 {
            return "Good (5-10m)"
        } else if locationAccuracy < 20.0 {
            return "Fair (10-20m)"
        } else {
            return "Poor (> 20m)"
        }
    }
    
    // Get when location was last updated as a human-readable string
    func getLastUpdateTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: lastUpdateTime)
    }
    
    // Check if location services are ready to use
    func isReady() -> Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
// This extension handles callbacks from the Core Location system
extension LocationManager: CLLocationManagerDelegate {
    
    // MARK: - Authorization Status Changes
    // Called when user grants or denies location permission
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {  // Update UI on main thread
            self.authorizationStatus = manager.authorizationStatus
            
            print("🔐 Authorization status changed to: \(self.authorizationStatus.rawValue)")
            
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Permission granted - start location updates
                self.locationError = nil
                self.startLocationUpdates()
                
            case .denied, .restricted:
                // Permission denied - stop updates and show error
                self.stopLocationUpdates()
                self.locationError = "Location access denied. Please enable in Settings."
                
            case .notDetermined:
                // Still waiting for user decision
                self.locationError = nil
                
            @unknown default:
                // Handle future iOS versions
                self.locationError = "Unknown authorization status"
            }
        }
    }
    
    // MARK: - Location Updates
    // Called when new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }  // Get most recent location
        
        DispatchQueue.main.async {  // Update UI on main thread
            self.currentLocation = location
            self.lastUpdateTime = Date()
            self.locationAccuracy = location.horizontalAccuracy
            
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("📍 Accuracy: \(location.horizontalAccuracy)m")
            
            // If following user, update map region
            if self.isFollowingUser {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            
            // Clear any previous location errors
            self.locationError = nil
        }
    }
    
    // MARK: - Location Errors
    // Called when location services fail
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {  // Update UI on main thread
            print("❌ Location error: \(error.localizedDescription)")
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied"
                case .locationUnknown:
                    self.locationError = "Unable to determine location"
                case .network:
                    self.locationError = "Network error - check internet connection"
                case .headingFailure:
                    self.locationError = "Compass heading unavailable"
                default:
                    self.locationError = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.locationError = "Unknown location error: \(error.localizedDescription)"
            }
            
            // Stop location updates on error
            self.stopLocationUpdates()
        }
    }
    
    // MARK: - Location Services Status
    // Called when location services are enabled/disabled system-wide
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {  // Update UI on main thread
            self.authorizationStatus = status
            print("🔐 Authorization changed to: \(status.rawValue)")
        }
    }
}
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
