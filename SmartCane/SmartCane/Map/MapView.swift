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
    @State private var showLocationAlert = false
    @State private var isPinMode = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showingSaveLocationSheet = false
    @State private var isTrackingUser = false
    
    var body: some View {
        NavigationView {
            ZStack {
                mapView
                searchBar
                controlButtons
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: setupView)
            .onChange(of: showingSaveLocationSheet) { _, newValue in
                handleSheetChange(newValue)
            }
            .sheet(isPresented: $showingSavedLocationDetail) {
                if let location = selectedSavedLocation {
                    SavedLocationDetailView(location: location)
                }
            }
            .sheet(isPresented: $showingSaveLocationSheet) {
                saveLocationSheet
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
    
    // MARK: - Map View
    private var mapView: some View {
        GeometryReader { geometry in
            Map(coordinateRegion: $locationManager.region, interactionModes: .all, showsUserLocation: true, userTrackingMode: .constant(.none), annotationItems: allMapAnnotations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
                    LocationPinView(
                        location: location,
                        color: isSearchResultLocation(location) ? .blue : .red,
                        onTap: {
                            selectedSavedLocation = location
                            showingSavedLocationDetail = true
                        }
                    )
                }
            }
            .onTapGesture(coordinateSpace: .local) { location in
                if isPinMode {
                    handleMapTap(at: location, mapSize: geometry.size)
                }
            }
            .overlay(
                // Custom user location indicator with direction
                Group {
                    if let userLocation = locationManager.currentLocation {
                        UserLocationIndicatorView(
                            coordinate: userLocation.coordinate,
                            heading: locationManager.userHeading,
                            mapRegion: locationManager.region
                        )
                    }
                }
            )
        }
    }
    
    // MARK: - All Map Annotations
    private var allMapAnnotations: [SavedLocation] {
        var annotations: [SavedLocation] = []
        
        // Add saved locations (these will be red pins)
        annotations.append(contentsOf: savedLocations)
        
        // Add search results (these will be blue pins)
        for item in searchResults {
            let searchLocation = SavedLocation(
                name: item.name ?? "Search Result", 
                address: item.placemark.title ?? "", 
                latitude: item.placemark.coordinate.latitude, 
                longitude: item.placemark.coordinate.longitude, 
                notes: "", 
                created_at: Date()
                
            )
            annotations.append(searchLocation)
        }
        
        return annotations
    }
    
    // MARK: - Helper Functions
    private func isSearchResultLocation(_ location: SavedLocation) -> Bool {
        // Check if this location is in our search results
        return searchResults.contains { item in
            item.placemark.coordinate.latitude == location.latitude &&
            item.placemark.coordinate.longitude == location.longitude
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
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
            
            // Show heading info when tracking (similar to Apple Maps)
            if isTrackingUser && locationManager.isHeadingEnabled {
                HStack {
                    Image(systemName: "location.north.line")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Heading: \(locationManager.getFullHeadingInfo())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    // Pin button
                    Button(action: togglePinMode) {
                        Image(systemName: isPinMode ? "mappin.slash" : "mappin")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(isPinMode ? Color.red : Color.orange)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    // Location button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Save Location Sheet
    private var saveLocationSheet: some View {
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
    
    // MARK: - Setup Functions
    private func setupView() {
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
    
    private func handleSheetChange(_ newValue: Bool) {
        print("📍 showingSaveLocationSheet changed to: \(newValue)")
        if newValue {
            if let coord = tappedCoordinate {
                print("📍 tappedCoordinate when sheet opens: (\(coord.latitude), \(coord.longitude))")
            } else {
                print("📍 tappedCoordinate when sheet opens: nil")
            }
        }
    }
    
    
    // MARK: - User Location Functions
    private func centerOnUserLocation() {
        print("📍 Location button tapped - centering and zooming to user location")
        
        // Check if location permission is granted
        if locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways {
            print("📍 Permission not granted, showing alert")
            showLocationAlert = true
            return
        }
        
        // Always center and zoom when button is tapped
        centerOnUserLocationWithMaxZoom()
        print("📍 Centered and zoomed to user location")
    }
    
    // MARK: - Center on User Location with Maximum Zoom
    private func centerOnUserLocationWithMaxZoom() {
        print("📍 Centering on user location with maximum zoom")
        
        // Check if we have current location
        if let location = locationManager.currentLocation {
            print("📍 Using existing location: \(location.coordinate)")
            // Center map on user location with maximum zoom (very small span)
            DispatchQueue.main.async {
                self.locationManager.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001) // Much more zoomed in
                )
                print("📍 Map region updated to: \(self.locationManager.region.center)")
            }
        } else {
            print("📍 No current location, starting location updates")
            // Start location updates
            locationManager.startLocationUpdates()
            
            // Wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let location = self.locationManager.currentLocation {
                    print("📍 Got location after delay: \(location.coordinate)")
                    self.locationManager.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001) // Maximum zoom
                    )
                    print("📍 Map region updated after delay: \(self.locationManager.region.center)")
                } else {
                    print("📍 Still no location after delay, using fallback location")
                    // Use a fallback location (NYC)
                    self.locationManager.region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                    )
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
            locationManager.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
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
    
    private func handleMapTap(at screenLocation: CGPoint, mapSize: CGSize) {
        // Convert screen tap point to map coordinates
        let currentRegion = locationManager.region
        
        // Calculate the actual coordinate from the tap point
        let coordinate = convertScreenPointToCoordinate(screenLocation, in: currentRegion, mapSize: mapSize)
        tappedCoordinate = coordinate
        showingSaveLocationSheet = true
        
        print("📍 Map tapped at screen point: \(screenLocation)")
        print("📍 Map size: \(mapSize)")
        print("📍 Converted to coordinate: (\(coordinate.latitude), \(coordinate.longitude))")
        print("📍 Pin mode: \(isPinMode)")
    }
    
    // Helper function to convert screen point to map coordinate
    private func convertScreenPointToCoordinate(_ point: CGPoint, in region: MKCoordinateRegion, mapSize: CGSize) -> CLLocationCoordinate2D {
        // Use the actual map view dimensions for precise calculation
        let centerX = mapSize.width / 2
        let centerY = mapSize.height / 2
        
        let deltaX = point.x - centerX
        let deltaY = point.y - centerY
        
        // Convert screen offset to coordinate offset
        // Note: Y axis is inverted (screen Y increases downward, but latitude increases upward)
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        
        // More precise calculation using actual map dimensions
        let latOffset = -deltaY / mapSize.height * latDelta
        let lonOffset = deltaX / mapSize.width * lonDelta
        
        // Calculate the final coordinate
        let latitude = region.center.latitude + latOffset
        let longitude = region.center.longitude + lonOffset
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
            created_at: Date()
        )
        
        onSave(newLocation)
        dismiss()
    }
}

// MARK: - Location Pin View
struct LocationPinView: View {
    let location: SavedLocation
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
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
            Button(action: onTap) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - User Location Indicator with Direction
struct UserLocationIndicatorView: View {
    let coordinate: CLLocationCoordinate2D
    let heading: CLLocationDirection
    let mapRegion: MKCoordinateRegion
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate the position of the user location on the map
            let userLocationPoint = convertCoordinateToPoint(coordinate, in: geometry.size, mapRegion: mapRegion)
            
            ZStack {
                // Main location dot
                Circle()
                    .fill(Color.blue)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .position(userLocationPoint)
                
                // Direction arrow
                if heading >= 0 {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(heading))
                        .position(
                            x: userLocationPoint.x + cos(Double(heading - 90) * .pi / 180) * 20,
                            y: userLocationPoint.y + sin(Double(heading - 90) * .pi / 180) * 20
                        )
                }
                
                // Heading text
                Text(String(format: "%.0f°", heading))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
                    .position(
                        x: userLocationPoint.x,
                        y: userLocationPoint.y + 25
                    )
            }
        }
    }
    
    // Convert coordinate to point on the map view
    private func convertCoordinateToPoint(_ coordinate: CLLocationCoordinate2D, in size: CGSize, mapRegion: MKCoordinateRegion) -> CGPoint {
        let latDelta = mapRegion.span.latitudeDelta
        let lonDelta = mapRegion.span.longitudeDelta
        
        let x = (coordinate.longitude - mapRegion.center.longitude) / lonDelta
        let y = (mapRegion.center.latitude - coordinate.latitude) / latDelta
        
        return CGPoint(
            x: size.width * (0.5 + x),
            y: size.height * (0.5 + y)
        )
    }
}

#Preview {
    MapView()
}
