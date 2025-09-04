import SwiftUI
import MapKit  // This framework provides map functionality and location services

struct MapView: View {
    // MARK: - State Properties
    // @StateObject creates a persistent object that survives view updates
    @StateObject private var locationManager = LocationManager()
    
    // @State properties are used for data that can change and trigger UI updates
    @State private var searchText = ""                    // Stores what user types in search bar
    @State private var showLocationSettings = false       // Controls when to show location permission alert
    @State private var mapType: MKMapType = .standard    // Controls map style (standard vs satellite)
    @State private var searchResults: [MKMapItem] = []   // Stores search results from Apple Maps
    @State private var isSearching = false               // Shows loading state during search
    
    var body: some View {
        // MARK: - Main Navigation Structure
        NavigationView {
            ZStack {  // ZStack layers views on top of each other (map in background, UI on top)
                // MARK: - Map Display
                // Map view shows the actual map with user location
                Map(coordinateRegion: $locationManager.region,  // Binds to location manager's region
                    interactionModes: .all,                    // Allows all map interactions (pinch, pan, etc.)
                    showsUserLocation: true)                   // Shows blue dot for user's location
                    .ignoresSafeArea(edges: .top)              // Makes map extend to top edge of screen
                
                // MARK: - Search Bar Overlay
                VStack {
                    searchBarView  // Custom search bar component
                        .padding()
                    
                    Spacer()  // Pushes search bar to top, other controls to bottom
                    
                    // MARK: - Map Controls Overlay
                    HStack {
                        Spacer()  // Pushes controls to right side
                        VStack(spacing: 8) {
                            // Location Status - Shows GPS accuracy and status
                            locationStatusView
                                .padding()
                                .background(.ultraThinMaterial)  // Creates translucent background
                                .cornerRadius(10)
                            
                            // Map Controls - Buttons for map functions
                            mapControlsView
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                
                // MARK: - Search Results Display
                // Shows search results below search bar when available
                if !searchResults.isEmpty && !searchText.isEmpty {
                    searchResultsView
                        .padding(.top, 80)  // Positions below search bar
                }
            }
            .navigationTitle("Map")  // Sets the title in navigation bar
            .navigationBarTitleDisplayMode(.inline)  // Makes title smaller and inline
            
            // MARK: - Location Permission Alert
            // Shows when user needs to enable location access
            .alert("Location Access Required", isPresented: $showLocationSettings) {
                Button("Open Settings") {
                    // Opens iOS Settings app to location permissions
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable location access in Settings to use the navigation features.")
            }
        }
    }
    
    // MARK: - Search Bar Component
    private var searchBarView: some View {
        VStack {
            HStack {
                // MARK: - Search Input Field
                HStack {
                    Image(systemName: "magnifyingglass")  // Search icon
                        .foregroundColor(.gray)
                    
                    // Text field for user input
                    TextField("Search for places...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())  // Removes default styling
                        .onSubmit {  // Triggers when user presses return/enter
                            performSearch()
                        }
                    
                    // Clear button (X) - only shows when there's text
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""           // Clears search text
                            searchResults = []        // Clears search results
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)  // Translucent background
                .cornerRadius(15)
                
                // MARK: - Location Button
                // Button to center map on user's current location
                Button(action: {
                    locationManager.centerOnUserLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(locationManager.currentLocation == nil)  // Disabled if no location available
            }
        }
    }
    
    // MARK: - Search Results Display
    private var searchResultsView: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 0) {  // LazyVStack only creates views as needed (better performance)
                    ForEach(searchResults, id: \.self) { item in  // Loop through search results
                        Button(action: {
                            selectSearchResult(item)  // Handle tap on search result
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Location name
                                    Text(item.name ?? "Unknown Location")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    // Address if available
                                    if let address = item.placemark.thoroughfare {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Chevron arrow to indicate tappable
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                        .buttonStyle(PlainButtonStyle())  // Removes default button styling
                        
                        Divider()  // Line between results
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(15)
            }
            .frame(maxHeight: 300)  // Limits height so it doesn't cover entire screen
        }
    }
    
    // MARK: - Location Status Display
    private var locationStatusView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: locationStatusIcon)  // Dynamic icon based on status
                    .foregroundColor(locationStatusColor)
                Text(locationManager.getLocationStatusDescription())
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Show error message if location services fail
            if let error = locationManager.locationError {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
            
            // MARK: - Location Details
            VStack(alignment: .leading, spacing: 2) {
                Text("Accuracy: \(locationManager.getLocationAccuracy())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Last Update: \(locationManager.getLastUpdateTime())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: 200)  // Limits width so it doesn't take too much space
    }
    
    // MARK: - Map Control Buttons
    private var mapControlsView: some View {
        VStack(spacing: 8) {
            // MARK: - Follow User Toggle
            // Button to make map follow user as they move
            Button(action: {
                if locationManager.isFollowingUser {
                    locationManager.stopFollowingUser()
                } else {
                    locationManager.followUserLocation()
                }
            }) {
                Image(systemName: locationManager.isFollowingUser ? "location.fill" : "location")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(locationManager.isFollowingUser ? Color.green : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(locationManager.currentLocation == nil)
            
            // MARK: - Map Type Toggle
            // Button to switch between standard and satellite map views
            Button(action: {
                mapType = mapType == .standard ? .satellite : .standard
            }) {
                Image(systemName: mapType == .standard ? "map" : "map.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Dynamic Location Status Icon
    // Returns different icons based on location permission and status
    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.isLocationEnabled ? "location.fill" : "location"
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location.circle"
        @unknown default:
            return "location.circle"
        }
    }
    
    // MARK: - Dynamic Location Status Color
    // Returns different colors based on location permission and status
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationManager.isLocationEnabled ? .green : .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    // MARK: - Search Functionality
    private func performSearch() {
        guard !searchText.isEmpty else { return }  // Don't search if text is empty
        
        isSearching = true
        let request = MKLocalSearch.Request()  // Create search request
        request.naturalLanguageQuery = searchText  // Set search term
        request.region = locationManager.region  // Search in current map area
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {  // Update UI on main thread
                isSearching = false
                if let error = error {
                    print("Search error: \(error)")
                    return
                }
                
                searchResults = response?.mapItems ?? []  // Store search results
            }
        }
    }
    
    // MARK: - Handle Search Result Selection
    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate  // Get coordinates of selected place
        
        // Move map to show selected location
        locationManager.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)  // Zoom level
        )
        
        searchResults = []  // Clear search results
        searchText = ""     // Clear search text
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    MapView()
}
