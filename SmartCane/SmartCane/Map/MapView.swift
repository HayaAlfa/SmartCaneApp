import SwiftUI
import MapKit
import CoreLocation

// MARK: - Notification Extension
extension Notification.Name {
    static let locationsUpdated = Notification.Name("locationsUpdated")
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var savedLocations: [SavedLocation] = []
    @State private var selectedSavedLocation: SavedLocation?
    @State private var showingSavedLocationDetail = false
    @State private var mapPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var showLocationAlert = false
    @State private var isPinMode = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showingSaveLocationSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map with iOS 15+ compatible pins with labels
                Map(coordinateRegion: $locationManager.region, annotationItems: savedLocations + searchResults.map { item in
                    SavedLocation(name: item.name ?? "Search Result", 
                                address: item.placemark.title ?? "", 
                                latitude: item.placemark.coordinate.latitude, 
                                longitude: item.placemark.coordinate.longitude, 
                                notes: "", 
                                dateAdded: Date())
                }) { location in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                        VStack(spacing: 0) {
                            // Location name label
                            Text(location.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .cornerRadius(4)
                                .foregroundColor(.primary)
                            
                            // Pin icon
                            Button(action: {
                                selectedSavedLocation = location
                                showingSavedLocationDetail = true
                            }) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .onTapGesture(coordinateSpace: .global) { location in
                    if isPinMode {
                        handleMapTap(at: location)
                    }
                }
                
                // Search bar at top
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for places...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                                searchResults = []
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
                
                // Location and Pin buttons at bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Pin button
                            Button(action: {
                                togglePinMode()
                            }) {
                                Image(systemName: isPinMode ? "mappin.slash" : "mappin")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(isPinMode ? Color.red : Color.orange)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            
                            // Location button
                Button(action: {
                                centerOnUserLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Request location permission when view appears
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocationPermission()
                }
                
                // Load saved locations
                loadSavedLocations()
                
                // Check if we need to center on a specific location
                checkForLocationCenter()
                
                // Listen for location updates from other parts of the app
                NotificationCenter.default.addObserver(
                    forName: .locationsUpdated,
                    object: nil,
                    queue: .main
                ) { _ in
                    loadSavedLocations()
                }
            }
            .onChange(of: showingSaveLocationSheet) { _, newValue in
                print("📍 showingSaveLocationSheet changed to: \(newValue)")
                if newValue {
                    if let coord = tappedCoordinate {
                        print("📍 tappedCoordinate when sheet opens: (\(coord.latitude), \(coord.longitude))")
                    } else {
                        print("📍 tappedCoordinate when sheet opens: nil")
                    }
                }
            }
            .sheet(isPresented: $showingSavedLocationDetail) {
                if let location = selectedSavedLocation {
                    SavedLocationDetailView(location: location)
                }
            }
            .sheet(isPresented: $showingSaveLocationSheet) {
                Group {
                    if let coordinate = tappedCoordinate {
                        SaveLocationView(coordinate: coordinate) { savedLocation in
                            savedLocations.append(savedLocation)
                            saveLocationsToUserDefaults()
                            isPinMode = false
                        }
                        .onAppear {
                            print("📍 Sheet showing with coordinate: (\(coordinate.latitude), \(coordinate.longitude))")
                        }
                    } else {
                        Text("No coordinate available")
                            .padding()
                            .onAppear {
                                print("📍 Sheet showing with NO coordinate - tappedCoordinate is nil")
                            }
                    }
                }
            }
            .alert("Location Access Required", isPresented: $showLocationAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location access to use the location feature.")
            }
        }
    }
    
    
    // MARK: - Center on User Location
    private func centerOnUserLocation() {
        print("📍 Location button tapped")
        print("📍 Authorization status: \(locationManager.authorizationStatus.rawValue)")
        print("📍 Current location: \(locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))")
        
        // Check if location permission is granted
        if locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways {
            print("📍 Permission not granted, showing alert")
            showLocationAlert = true
            return
        }
        
        // Check if we have current location
        if let location = locationManager.currentLocation {
            print("📍 Using existing location: \(location.coordinate)")
            // Center map on user location
            mapPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            print("📍 No current location, starting location updates")
            // Start location updates
            locationManager.startLocationUpdates()
            
            // Wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let location = self.locationManager.currentLocation {
                    print("📍 Got location after delay: \(location.coordinate)")
                    self.mapPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                } else {
                    print("📍 Still no location after delay, using fallback location")
                    // Use a fallback location (NYC)
                    self.mapPosition = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
    }
    
    // MARK: - Check for Location Center
    private func checkForLocationCenter() {
        // Check if there are coordinates stored from SavedLocationsView
        let latitude = UserDefaults.standard.double(forKey: "MapCenterLatitude")
        let longitude = UserDefaults.standard.double(forKey: "MapCenterLongitude")
        let name = UserDefaults.standard.string(forKey: "MapCenterName") ?? ""
        
        if latitude != 0.0 && longitude != 0.0 {
            print("📍 Centering map on saved location: \(name) at (\(latitude), \(longitude))")
            
            // Center map on the saved location
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            
            // Clear the stored coordinates so it doesn't happen again
            UserDefaults.standard.removeObject(forKey: "MapCenterLatitude")
            UserDefaults.standard.removeObject(forKey: "MapCenterLongitude")
            UserDefaults.standard.removeObject(forKey: "MapCenterName")
        }
    }
    
    // MARK: - Load Saved Locations
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "SavedLocations"),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = decoded
            print("📍 Loaded \(savedLocations.count) saved locations for map pins")
        }
    }
    
    // MARK: - Search Functionality
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = locationManager.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    print("Search error: \(error)")
                    return
                }
                
                searchResults = response?.mapItems ?? []
                
                // Move map to first result
                if let firstResult = searchResults.first {
                    let coordinate = firstResult.placemark.coordinate
                    locationManager.region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
    }
    
    // MARK: - Pin Mode Functions
    private func togglePinMode() {
        isPinMode.toggle()
        print("📍 Pin mode: \(isPinMode ? "ON" : "OFF")")
    }
    
    private func handleMapTap(at screenLocation: CGPoint) {
        // Use the current map region from locationManager
        let currentRegion = locationManager.region
        
        // For simplicity, we'll use the center of the current map region
        // In a real implementation, you'd convert screen point to coordinate
        let coordinate = currentRegion.center
        tappedCoordinate = coordinate
        showingSaveLocationSheet = true
        
        print("📍 Map tapped at coordinate: (\(coordinate.latitude), \(coordinate.longitude))")
        print("📍 Pin mode: \(isPinMode)")
        if let coord = tappedCoordinate {
            print("📍 tappedCoordinate set to: (\(coord.latitude), \(coord.longitude))")
        } else {
            print("📍 tappedCoordinate set to: nil")
        }
    }
    
    // MARK: - Save Locations to UserDefaults
    private func saveLocationsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: "SavedLocations")
            
            // Post notification to update other parts of the app
            NotificationCenter.default.post(name: .locationsUpdated, object: nil)
        }
    }
}

// MARK: - Simple Location Detail View
struct SavedLocationDetailView: View {
    let location: SavedLocation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(location.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(location.address)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button("Get Directions") {
                    let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    mapItem.name = location.name
                    mapItem.openInMaps()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Save Location View
struct SaveLocationView: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (SavedLocation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var locationNotes = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Save Location")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top)
                .onAppear {
                    print("📍 SaveLocationView appeared with coordinate: \(coordinate)")
                }
                
                // Coordinate info
                VStack(spacing: 8) {
                    Text("Coordinates")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Latitude:")
                        Spacer()
                        Text(String(format: "%.6f", coordinate.latitude))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Longitude:")
                        Spacer()
                        Text(String(format: "%.6f", coordinate.longitude))
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Input fields
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Location Name *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter location name", text: $locationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Address (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter address", text: $locationAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Notes (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter notes", text: $locationNotes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Spacer()
                
                // Save button
                Button("Save Location") {
                    saveLocation()
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationName.isEmpty)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveLocation() {
        let newLocation = SavedLocation(
            name: locationName,
            address: locationAddress.isEmpty ? "Unknown Address" : locationAddress,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            notes: locationNotes,
            dateAdded: Date()
        )
        
        onSave(newLocation)
        dismiss()
    }
}


#Preview {
    MapView()
}
