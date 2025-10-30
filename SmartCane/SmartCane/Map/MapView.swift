import SwiftUI
import MapKit
import CoreLocation
import AVFoundation
import Speech
import MediaPlayer
import UserNotifications
import os.log

// MARK: - Notification Extension
extension Notification.Name {
    static let locationsUpdated = Notification.Name("locationsUpdated")
}

// MARK: - MapView Search
private extension MapView {
    func performSearch() {
        guard !searchText.isEmpty else { return }
        // update history (dedup and cap to 5) and persist
        var newHistory = searchHistory.filter { $0.caseInsensitiveCompare(searchText) != .orderedSame }
        newHistory.insert(searchText, at: 0)
        if newHistory.count > 5 { newHistory = Array(newHistory.prefix(5)) }
        searchHistory = newHistory
        saveSearchHistory()
        var request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = testRegion
        MKLocalSearch(request: request).start { response, error in
            if let error = error {
                print("🔎 Search error: \(error.localizedDescription)")
                return
            }
            let results = response?.mapItems ?? []
            DispatchQueue.main.async {
                self.searchResults = results
                if let first = results.first {
                    let coord = first.placemark.coordinate
                    self.testRegion = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
    
    func loadSearchHistory() {
        if let saved = UserDefaults.standard.array(forKey: searchHistoryDefaultsKey) as? [String] {
            searchHistory = Array(saved.prefix(5))
        }
    }
    
    func saveSearchHistory() {
        UserDefaults.standard.set(Array(searchHistory.prefix(5)), forKey: searchHistoryDefaultsKey)
    }
}

// MARK: - Map Annotation Item
struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String?
    let type: AnnotationType
    let savedLocation: SavedLocation?
    
    enum AnnotationType {
        case savedLocation
        case navigation
    }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = NavigationViewModel()
    
    // Pin functionality
    @State private var savedLocations: [SavedLocation] = []
    @State private var selectedSavedLocation: SavedLocation?
    @State private var showingSavedLocationDetail = false
    @State private var showLocationAlert = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showingSaveLocationSheet = false
    @State private var isPinMode = false
    
    // Navigation state
    @State private var startText = ""
    @State private var endText = ""
    @State private var isNavigationMode = false
    @State private var mapID = UUID()
    @State private var testRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showZoomSuccess = false
 
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @FocusState private var isSearchFocused: Bool
    @State private var searchHistory: [String] = []
    private let searchHistoryDefaultsKey = "MapView.SearchHistory"
    
    private var searchOverlay: some View {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search for places...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                                .onSubmit { performSearch() }
                            if !searchText.isEmpty {
                                Button("Clear") {
                                    searchText = ""
                                    searchResults = []
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)

            if isSearchFocused {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(searchHistory.prefix(8).enumerated()), id: \.offset) { _, term in
                        Button(action: {
                            searchText = term
                            isSearchFocused = false
                            performSearch()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.gray)
                                Text(term)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if term != searchHistory.last { Divider() }
                    }
                    if searchHistory.isEmpty {
                        Text("No recent searches")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(10)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
            } else if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(searchResults.prefix(5).enumerated()), id: \.offset) { _, item in
                                    Button(action: {
                                        let coord = item.placemark.coordinate
                                        testRegion = MKCoordinateRegion(
                                            center: coord,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                        let temp = SavedLocation(
                                            name: item.name ?? "Search Result",
                                            address: item.placemark.title ?? "",
                                            latitude: coord.latitude,
                                            longitude: coord.longitude,
                                            notes: "",
                                            dateAdded: Date()
                                        )
                                        if !savedLocations.contains(where: { $0.latitude == temp.latitude && $0.longitude == temp.longitude }) {
                                            savedLocations.append(temp)
                                        }
                                    }) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "mappin.and.ellipse")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "Unnamed")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                        }
                                        .padding(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    if item != searchResults.last { Divider() }
                                }
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        Spacer()
                    }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Full screen map in background (single MKMapView for device reliability)
                UIKitMapView(
                    region: $testRegion,
                    annotations: savedLocations,
                    route: viewModel.route,
                    onMapTap: { coordinate in
                        tappedCoordinate = coordinate
                        showingSaveLocationSheet = true
                    }
                )
                .ignoresSafeArea(.all)
                .id(mapID) // Force map refresh when ID changes
                .overlay(
                    searchOverlay
                    .padding(.top, 8)
                    , alignment: .top
                )
                // Route is rendered directly inside UIKitMapView now
                .overlay(
                    // Success notification
                    Group {
                        if showZoomSuccess {
                            VStack {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Zoomed to your location!")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(10)
                                .padding(.top, 100)
                                Spacer()
                            }
                        }
                    }
                )
                
                // Tap handled directly inside UIKitMapView via gesture recognizer for accuracy
                
                // Control panel overlay
                VStack {
                        // Top section with simple controls
                        VStack(spacing: 10) {
                        if isNavigationMode {
                            // Navigation input boxes
                            VStack(spacing: 8) {
                                    
                                    // Show cancel button when navigating
                                    if viewModel.isNavigating {
                                    Button("Cancel") {
                                        print("🛑 Cancel button tapped (overlay) - clearing route and exiting navigation mode")
                                            viewModel.clearRoute()
                                        isNavigationMode = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            // Ensure playback route restored after recording session
                                            do {
                                                let session = AVAudioSession.sharedInstance()
                                                try session.setCategory(.playback, mode: .spokenAudio, options: [.defaultToSpeaker])
                                                try session.setActive(true, options: .notifyOthersOnDeactivation)
                                                try session.overrideOutputAudioPort(.speaker)
                                            } catch { }
                                            viewModel.speak("Walking navigation cancelled. Route cleared.")
                                            }
                                        }
                                        .font(.title3)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .accessibilityLabel("Cancel current navigation and start new route")
                                        .accessibilityHint("Stops current navigation and sets up new route")
                                    }
                                
            }
            .padding()
                            .background(Color.black.opacity(0.7))
            .cornerRadius(15)
            .padding(.horizontal)
                        }
            }
            
            Spacer()
    
                        // Bottom-right corner buttons
        VStack {
            Spacer()
            HStack {
                Spacer()
                                VStack(spacing: 10) {
                            // Compact Testing/Real mode switch (bottom-right, above pin)
                            HStack {
                                Toggle("", isOn: $viewModel.isTestingMode)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                            }
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .scaleEffect(0.9)
                            
                                    // Pin Mode Button
                                    Button(action: {
                                        isPinMode.toggle()
                                    }) {
                                        Image(systemName: isPinMode ? "mappin.circle.fill" : "mappin.circle")
                                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                                            .background(isPinMode ? Color.orange : Color.gray)
                            .clipShape(Circle())
                                            .shadow(radius: 3)
                                    }
                                    
                                    // Center Location Button
                                    Button(action: {
                                        centerOnCurrentLocation()
                                    }) {
                                        Image(systemName: "location.circle.fill")
                                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                                            .background(Color.blue)
                            .clipShape(Circle())
                                            .shadow(radius: 3)
                                    }

                    
                }
                .padding(.trailing, 20)
                                .padding(.bottom, 100) // Above the instruction area
                            }
                        }
                        
                        // Bottom section with current instruction
                    if let step = viewModel.currentInstruction {
                        Text("Next: \(step)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            .shadow(color: .black, radius: 3, x: 1, y: 1)
                    }
                    
                    // Voice recognition status indicator (only when screen is on)
                    if viewModel.isListening {
                        Text("🎤 Listening...")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: setupView)
                .onChange(of: showingSaveLocationSheet) { _, newValue in
                    handleSheetChange(newValue)
                }
                // Zoom background map to route when it becomes available
                .onChange(of: viewModel.route) { _, newRoute in
                    if let route = newRoute {
                        print("🗺️ Route received in MapView – zooming to route bounds")
                        let bounds = route.polyline.boundingMapRect
                        let region = MKCoordinateRegion(bounds)
                        // Add a bit of padding by scaling span smaller
                        let padded = MKCoordinateRegion(
                            center: region.center,
                            span: MKCoordinateSpan(
                                latitudeDelta: max(region.span.latitudeDelta * 1.2, 0.002),
                                longitudeDelta: max(region.span.longitudeDelta * 1.2, 0.002)
                            )
                        )
                        testRegion = padded
                    } else {
                        print("ℹ️ Route cleared from MapView")
                    }
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
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Walking Route Ready"),
                    message: Text("Walking route from start to destination is set up. Say 'start' or 'cancel', or use the buttons below."),
                    primaryButton: .default(Text("Start Walking")) {
                        viewModel.stopListening()
                        viewModel.startNavigation()
                    },
                    secondaryButton: .cancel {
                        print("🛑 Cancel button tapped (alert) - clearing route and exiting navigation mode")
                        viewModel.stopListening()
                        viewModel.clearRoute()
                        isNavigationMode = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Ensure playback route restored (playback category)
                            do {
                                let session = AVAudioSession.sharedInstance()
                                try session.setCategory(.playback, mode: .spokenAudio, options: [])
                                try session.setActive(true, options: .notifyOthersOnDeactivation)
                            } catch { }
                        viewModel.speak("Walking navigation cancelled. Route cleared.")
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - All Map Annotations
    private var allMapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Add saved locations (these will be red pins)
        for location in savedLocations {
            annotations.append(MapAnnotationItem(
                id: location.id.uuidString,
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                title: location.name,
                subtitle: location.address,
                type: .savedLocation,
                savedLocation: location
            ))
        }
        
        // Add navigation annotations (start/end points)
        for annotation in viewModel.annotations {
            annotations.append(MapAnnotationItem(
                id: annotation.id.uuidString,
                coordinate: annotation.coordinate,
                title: annotation.name,
                subtitle: nil,
                type: .navigation,
                savedLocation: nil
            ))
        }
        
        
        for annotation in annotations {
            
        }
        return annotations
    }
    
    // MARK: - Save Location Sheet
    private var saveLocationSheet: some View {
        Group {
            if let coordinate = tappedCoordinate {
                SaveLocationView(coordinate: coordinate) { savedLocation in
                    savedLocations.append(savedLocation)
                    saveLocationsToUserDefaults()
                }
                .onAppear {
                    
                }
            } else {
                Text("No coordinate available")
                    .padding()
                    .onAppear {
                        
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
        
        // Set map region to show saved locations
        if !savedLocations.isEmpty {
            // Calculate center point from saved locations
            let avgLat = savedLocations.map { $0.latitude }.reduce(0, +) / Double(savedLocations.count)
            let avgLon = savedLocations.map { $0.longitude }.reduce(0, +) / Double(savedLocations.count)
            
            locationManager.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        
        } else {
            // Default to San Francisco area if no saved locations
            locationManager.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        
        }
        
        // Check if we need to center on a specific location
        checkForLocationCenter()
        
        // Check for navigation coordinates from My Routes
        checkForNavigationCoordinates()
        
        // Initialize navigation view model
        viewModel.requestPermission()
        
        // Listen for location updates from other parts of the app
        NotificationCenter.default.addObserver(
            forName: .locationsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            loadSavedLocations()
        }

        // Load persisted search history
        loadSearchHistory()
    }
    
    // MARK: - My Routes Integration
    private func checkForNavigationCoordinates() {
        // Check if there are coordinates stored from MyRoutesView
        let startLat = UserDefaults.standard.double(forKey: "NavigationStartLatitude")
        let startLon = UserDefaults.standard.double(forKey: "NavigationStartLongitude")
        let endLat = UserDefaults.standard.double(forKey: "NavigationEndLatitude")
        let endLon = UserDefaults.standard.double(forKey: "NavigationEndLongitude")
        let autoStart = UserDefaults.standard.bool(forKey: "AutoStartNavigation")
        
        if startLat != 0.0 && startLon != 0.0 && endLat != 0.0 && endLon != 0.0 {
            print("📍 Navigation coordinates found from My Routes")
            
            // Set the coordinates in the text fields
            startText = "\(startLat),\(startLon)"
            endText = "\(endLat),\(endLon)"
            
            // Switch to navigation mode
            isNavigationMode = true
            
            // Clear the stored coordinates so it doesn't happen again
            UserDefaults.standard.removeObject(forKey: "NavigationStartLatitude")
            UserDefaults.standard.removeObject(forKey: "NavigationStartLongitude")
            UserDefaults.standard.removeObject(forKey: "NavigationEndLatitude")
            UserDefaults.standard.removeObject(forKey: "NavigationEndLongitude")
            UserDefaults.standard.removeObject(forKey: "AutoStartNavigation")
            
            // Auto-setup the route after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewModel.startText = self.startText
                self.viewModel.endText = self.endText
                self.viewModel.shouldAutoStartNavigation = autoStart
                self.viewModel.setupRoute()
            }
        }
    }
    
    // MARK: - Public function to set navigation coordinates (called from MyRoutesView)
    func setNavigationCoordinates(startLat: Double, startLon: Double, endLat: Double, endLon: Double) {
        startText = "\(startLat),\(startLon)"
        endText = "\(endLat),\(endLon)"
        isNavigationMode = true
        
        // Auto-setup the route
        viewModel.startText = startText
        viewModel.endText = endText
        viewModel.setupRoute()
    }
    
    
    
    // MARK: - Center on Current Location
    private func centerOnCurrentLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
            return
        }
        
        if locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways {
            showLocationAlert = true
            return
        }
        
        centerOnUserLocationWithMaxZoom()
    }
    
    private func centerOnUserLocationWithMaxZoom() {
        guard let location = locationManager.currentLocation else {
            locationManager.startLocationUpdates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let location = self.locationManager.currentLocation {
                    self.centerOnLocationWithTwoStep(location)
                } else {
                    let nycLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
                    self.centerOnLocationWithTwoStep(nycLocation)
                }
            }
            return
        }
        
        centerOnLocationWithTwoStep(location)
    }
    
    private func centerOnLocationWithTwoStep(_ location: CLLocation) {
        print("📍 Using location: \(location.coordinate)")
        
        // First jump to a completely different location to make the change visible
        print("📍 Step 1: Jumping to NYC first...")
        testRegion = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // Then after a brief delay, zoom to your location
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📍 Step 2: Now zooming to your location...")
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            print("📍 Setting testRegion to: \(newRegion.center), span: \(newRegion.span)")
            self.testRegion = newRegion
            print("📍 testRegion updated successfully")
            
            // Show success notification
            self.showZoomSuccess = true
            print("📍 Showing success notification")
            
            // Hide notification after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showZoomSuccess = false
                print("📍 Hiding success notification")
            }
        }
    }
    
    
    
    
    private func handleSheetChange(_ newValue: Bool) {
        
        if newValue {
            if let coord = tappedCoordinate {
                
            } else {
                
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
            
            for location in savedLocations {
                
            }
        } else {
            
        }
    }
    
    
    private func handleMapTap(at screenLocation: CGPoint, mapSize: CGSize) {
        // Simple coordinate conversion
        let currentRegion = viewModel.region
        
        // Calculate the actual coordinate from the tap point
        let coordinate = convertScreenPointToCoordinate(screenLocation, in: currentRegion, mapSize: mapSize)
        tappedCoordinate = coordinate
        showingSaveLocationSheet = true
        
        
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
            dateAdded: Date()
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

// MARK: - Navigation Pin View
struct NavigationPinView: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Title label
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
                .foregroundColor(.white)
            
            // Pin icon
            Image(systemName: title == "Start" ? "play.circle.fill" : "flag.circle.fill")
                .font(.title)
                .foregroundColor(color)
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

// SmartCaneNavigationViewModel moved to SmartCane/SmartCane/Map/SmartCaneNavigationViewModel.swift

// MARK: - Route Overlay
struct RouteOverlay: UIViewRepresentable {
    @Binding var route: MKRoute?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        if let route = route {
            mapView.addOverlay(route.polyline)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemGreen
                renderer.lineWidth = 6
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

 

// MARK: - UIKit MKMapView wrapper
struct UIKitMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [SavedLocation] = []
    var route: MKRoute? = nil
    var onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.showsUserLocation = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.isUserInteractionEnabled = true
        map.delegate = context.coordinator
        // Add an accurate tap recognizer to convert touch to coordinate
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        map.addGestureRecognizer(tap)
        map.setRegion(region, animated: false)
        
        // Add initial annotations
        let anns = annotations.map { loc -> MKPointAnnotation in
            let a = MKPointAnnotation()
            a.title = loc.name
            a.subtitle = loc.address
            a.coordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            return a
        }
        map.addAnnotations(anns)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Only set if meaningfully different to avoid animation spam
        let current = uiView.region
        let new = region
        let centerChanged = abs(current.center.latitude - new.center.latitude) > 1e-6 || abs(current.center.longitude - new.center.longitude) > 1e-6
        let spanChanged = abs(current.span.latitudeDelta - new.span.latitudeDelta) > 1e-6 || abs(current.span.longitudeDelta - new.span.longitudeDelta) > 1e-6
        if centerChanged || spanChanged {
            context.coordinator.isProgrammaticChange = true
            uiView.setRegion(new, animated: true)
            // Clear the flag shortly after to allow user gestures to update binding
            DispatchQueue.main.async { context.coordinator.isProgrammaticChange = false }
        }
        // Refresh annotations if counts differ (simple heuristic)
        let nonUser = uiView.annotations.filter { !($0 is MKUserLocation) }
        if nonUser.count != annotations.count {
            uiView.removeAnnotations(nonUser)
            let anns = annotations.map { loc -> MKPointAnnotation in
                let a = MKPointAnnotation()
                a.title = loc.name
                a.subtitle = loc.address
                a.coordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                return a
            }
            uiView.addAnnotations(anns)
        }

        // Update route overlay reliably on device
        let existingPolylines = uiView.overlays.compactMap { $0 as? MKPolyline }
        if let route = route {
            // If no polyline or different, reset
            if existingPolylines.isEmpty || existingPolylines.first?.pointCount != route.polyline.pointCount {
                uiView.removeOverlays(uiView.overlays)
                uiView.addOverlay(route.polyline)
                // Zoom to route with slight padding
                let bounds = route.polyline.boundingMapRect
                let padded = bounds.insetBy(dx: -bounds.size.width * 0.1, dy: -bounds.size.height * 0.1)
                context.coordinator.isProgrammaticChange = true
                uiView.setVisibleMapRect(padded, edgePadding: UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20), animated: true)
                DispatchQueue.main.async { context.coordinator.isProgrammaticChange = false }
                print("✅ UIKitMapView: route overlay updated and zoomed (")
            }
        } else {
            if !existingPolylines.isEmpty {
                uiView.removeOverlays(existingPolylines)
                print("ℹ️ UIKitMapView: route overlay cleared")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UIKitMapView
        var isProgrammaticChange = false
        init(parent: UIKitMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // If user changed the map (pinch/drag), propagate back into SwiftUI binding
            if !isProgrammaticChange {
                let new = mapView.region
                // Print once to help diagnose device gestures
                print("🫰 Map regionDidChange (user): center=(\(new.center.latitude), \(new.center.longitude)) span=(\(new.span.latitudeDelta), \(new.span.longitudeDelta))")
                DispatchQueue.main.async {
                    self.parent.region = new
                }
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            print("📍 Map tap at coordinate: (\(coord.latitude), \(coord.longitude))")
            if let callback = parent.onMapTap {
                callback(coord)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = .systemGreen
                r.lineWidth = 6
                return r
            }
            return MKOverlayRenderer()
        }
    }
}

#Preview {
    MapView()
}
