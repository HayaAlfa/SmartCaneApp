//  LocationManager.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 8/30/25.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject {
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
    @Published var lastUpdateTime: Date?
    
    private var manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3.0
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = false
        manager.activityType = .fitness
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Location Permission
    func requestLocationPermission() {
        print("🔐 Requesting location permission…")
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Start/Stop Updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Location permission not granted")
            return
        }
        print("🚀 Starting location updates…")
        manager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        print("⏹️ Stopping location updates…")
        manager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    // MARK: - Map Controls
    func centerOnUserLocation() {
        guard let location = currentLocation else {
            print("❌ Cannot center map – no current location")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    func followUserLocation() {
        print("👥 Following user location")
        isFollowingUser = true
        if !isLocationEnabled {
            startLocationUpdates()
        }
    }
    
    func stopFollowingUser() {
        print("🚫 Stopped following user location")
        isFollowingUser = false
    }
    
    // MARK: - Info Helpers
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
        @unknown default:
            return "Unknown status"
        }
    }
    
    func getLocationAccuracy() -> String {
        if locationAccuracy == 0.0 {
            return "Unknown"
        } else if locationAccuracy < 5.0 {
            return "Excellent (< 5m)"
        } else if locationAccuracy < 10.0 {
            return "Good (5–10m)"
        } else if locationAccuracy < 20.0 {
            return "Fair (10–20m)"
        } else {
            return "Poor (> 20m)"
        }
    }
    
    func getLastUpdateTime() -> String {
        guard let lastUpdateTime else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: lastUpdateTime)
    }
    
    // Human-readable current location string
    func getCurrentLocationString() -> String {
        guard let location = currentLocation else {
            return "Location not available"
        }
        return String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    func isReady() -> Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("🔐 Authorization status changed to: \(self.authorizationStatus.rawValue)")
            
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.startLocationUpdates()
            case .denied, .restricted:
                self.stopLocationUpdates()
                self.locationError = "Location access denied. Please enable in Settings."
            case .notDetermined:
                self.locationError = nil
            @unknown default:
                self.locationError = "Unknown authorization status"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.lastUpdateTime = Date()
            self.locationAccuracy = location.horizontalAccuracy
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            if self.isFollowingUser {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Location error: \(error.localizedDescription)")
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied"
                case .locationUnknown:
                    self.locationError = "Unable to determine location"
                case .network:
                    self.locationError = "Network error"
                case .headingFailure:
                    self.locationError = "Compass heading unavailable"
                default:
                    self.locationError = "Error: \(error.localizedDescription)"
                }
            } else {
                self.locationError = "Unknown location error: \(error.localizedDescription)"
            }
            self.stopLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("🔐 Authorization changed to: \(status.rawValue)")
        }
    }
}
