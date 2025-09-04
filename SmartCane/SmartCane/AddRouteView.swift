import SwiftUI
import MapKit

struct AddRouteView: View {
    // MARK: - Properties
    let onSave: (SavedRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - Form State
    @State private var routeName = ""
    @State private var selectedOrigin: SavedLocation?
    @State private var selectedDestination: SavedLocation?
    @State private var selectedRouteType = RouteType.daily.rawValue
    @State private var selectedTransportMode = TransportMode.walking.rawValue
    @State private var notes = ""
    @State private var showingOriginPicker = false
    @State private var showingDestinationPicker = false
    @State private var showingAddLocation = false
    
    // MARK: - Validation
    var isFormValid: Bool {
        !routeName.isEmpty && selectedOrigin != nil && selectedDestination != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Route Information Section
                Section {
                    TextField("Route Name", text: $routeName)
                        .textContentType(.name)
                    
                    Picker("Route Type", selection: $selectedRouteType) {
                        ForEach(RouteType.allCases, id: \.self) { routeType in
                            HStack {
                                Image(systemName: routeType.icon)
                                    .foregroundColor(routeType.color)
                                Text(routeType.rawValue)
                            }
                            .tag(routeType.rawValue)
                        }
                    }
                    
                    Picker("Transport Mode", selection: $selectedTransportMode) {
                        ForEach(TransportMode.allCases, id: \.self) { transportMode in
                            HStack {
                                Image(systemName: transportMode.icon)
                                    .foregroundColor(transportMode.color)
                                Text(transportMode.rawValue)
                            }
                            .tag(transportMode.rawValue)
                        }
                    }
                } header: {
                    Text("Route Information")
                }
                
                // MARK: - Origin and Destination Section
                Section {
                    // Origin Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                            Text("Origin")
                                .font(.headline)
                        }
                        
                        if let origin = selectedOrigin {
                            // Show selected origin
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(origin.name ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(origin.address ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Change") {
                                    showingOriginPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            // Show origin selection button
                            Button(action: {
                                showingOriginPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Select Origin")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Destination Selection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("Destination")
                                .font(.headline)
                        }
                        
                        if let destination = selectedDestination {
                            // Show selected destination
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(destination.name ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(destination.address ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Change") {
                                    showingDestinationPicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            // Show destination selection button
                            Button(action: {
                                showingDestinationPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Select Destination")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Quick Actions
                    HStack {
                        Button("Use Current Location as Origin") {
                            useCurrentLocationAsOrigin()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Use Current Location as Destination") {
                            useCurrentLocationAsDestination()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Route Points")
                } footer: {
                    Text("Select the starting point (origin) and ending point (destination) for your route")
                }
                
                // MARK: - Additional Information Section
                Section {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Additional Information")
                } footer: {
                    Text("Add any notes or reminders about this route")
                }
                
                // MARK: - Route Preview Section
                if selectedOrigin != nil && selectedDestination != nil {
                    Section {
                        RoutePreviewCard(
                            origin: selectedOrigin!,
                            destination: selectedDestination!,
                            routeType: selectedRouteType,
                            transportMode: selectedTransportMode
                        )
                    } header: {
                        Text("Route Preview")
                    }
                }
            }
            .navigationTitle("Add Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRoute()
                    }
                    .disabled(!isFormValid)
                }
            }
            
            // MARK: - Sheets
            .sheet(isPresented: $showingOriginPicker) {
                LocationPickerView(
                    title: "Select Origin",
                    selectedLocation: $selectedOrigin,
                    locations: coreDataManager.savedLocations
                )
            }
            
            .sheet(isPresented: $showingDestinationPicker) {
                LocationPickerView(
                    title: "Select Destination",
                    selectedLocation: $selectedDestination,
                    locations: coreDataManager.savedLocations
                )
            }
            
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    // Location is automatically saved by CoreDataManager
                    // Refresh the locations list
                    coreDataManager.loadSavedLocations()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Use current location as origin
    private func useCurrentLocationAsOrigin() {
        guard let currentLocation = locationManager.currentLocation else {
            // Show alert that location is not available
            return
        }
        
        // Create a temporary location object for current location
        let currentLocationObject = SavedLocation(context: coreDataManager.container.viewContext)
        currentLocationObject.id = UUID()
        currentLocationObject.name = "Current Location"
        currentLocationObject.address = "GPS Coordinates"
        currentLocationObject.latitude = currentLocation.coordinate.latitude
        currentLocationObject.longitude = currentLocation.coordinate.longitude
        currentLocationObject.category = "Other"
        currentLocationObject.notes = "Current GPS location"
        currentLocationObject.dateAdded = Date()
        
        selectedOrigin = currentLocationObject
    }
    
    // Use current location as destination
    private func useCurrentLocationAsDestination() {
        guard let currentLocation = locationManager.currentLocation else {
            // Show alert that location is not available
            return
        }
        
        // Create a temporary location object for current location
        let currentLocationObject = SavedLocation(context: coreDataManager.container.viewContext)
        currentLocationObject.id = UUID()
        currentLocationObject.name = "Current Location"
        currentLocationObject.address = "GPS Coordinates"
        currentLocationObject.latitude = currentLocation.coordinate.latitude
        currentLocationObject.longitude = currentLocation.coordinate.longitude
        currentLocationObject.category = "Other"
        currentLocationObject.notes = "Current GPS location"
        currentLocationObject.dateAdded = Date()
        
        selectedDestination = currentLocationObject
    }
    
    // Save the route
    private func saveRoute() {
        guard let origin = selectedOrigin,
              let destination = selectedDestination else { return }
        
        // Create the new route
        let newRoute = SavedRoute(context: coreDataManager.container.viewContext)
        newRoute.id = UUID()
        newRoute.name = routeName
        newRoute.origin = origin
        newRoute.destination = destination
        newRoute.routeType = selectedRouteType
        newRoute.preferredTransportMode = selectedTransportMode
        newRoute.notes = notes
        newRoute.dateCreated = Date()
        
        // Save to Core Data
        coreDataManager.saveContext()
        
        // Call the onSave closure
        onSave(newRoute)
        
        // Dismiss the view
        dismiss()
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    let title: String
    @Binding var selectedLocation: SavedLocation?
    let locations: [SavedLocation]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingAddLocation = false
    
    var filteredLocations: [SavedLocation] {
        if searchText.isEmpty {
            return locations
        } else {
            return locations.filter { location in
                location.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                location.address?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search locations...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                }
                .padding()
                
                // Locations list
                if filteredLocations.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Locations Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add a new location to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Add Location") {
                            showingAddLocation = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List(filteredLocations) { location in
                        LocationRow(location: location) {
                            selectedLocation = location
                            dismiss()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add New") {
                        showingAddLocation = true
                    }
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    // Location is automatically saved
                }
            }
        }
    }
}

// MARK: - Location Row Component
struct LocationRow: View {
    let location: SavedLocation
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: getCategoryIcon())
                    .font(.title2)
                    .foregroundColor(getCategoryColor())
                    .frame(width: 40, height: 40)
                    .background(getCategoryColor().opacity(0.1))
                    .clipShape(Circle())
                
                // Location details
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(location.address ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let notes = location.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper methods for category display
    private func getCategoryIcon() -> String {
        guard let categoryString = location.category,
              let category = SavedLocation.LocationCategory(rawValue: categoryString) else {
            return "mappin"
        }
        return category.icon
    }
    
    private func getCategoryColor() -> Color {
        guard let categoryString = location.category,
              let category = SavedLocation.LocationCategory(rawValue: categoryString) else {
            return .gray
        }
        return category.color
    }
}

// MARK: - Route Preview Card
struct RoutePreviewCard: View {
    let origin: SavedLocation
    let destination: SavedLocation
    let routeType: String
    let transportMode: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Route type and transport mode
            HStack {
                Image(systemName: getRouteTypeIcon())
                    .foregroundColor(getRouteTypeColor())
                Text(routeType)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: getTransportModeIcon())
                    .foregroundColor(getTransportModeColor())
                Text(transportMode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Route visualization
            HStack(spacing: 20) {
                // Origin
                VStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("Origin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Route line
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 2)
                
                // Destination
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("Destination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Location names
            VStack(spacing: 8) {
                Text(origin.name ?? "Unknown Origin")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Text("→")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(destination.name ?? "Unknown Destination")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // Helper methods
    private func getRouteTypeIcon() -> String {
        guard let routeTypeEnum = RouteType(rawValue: routeType) else {
            return "map"
        }
        return routeTypeEnum.icon
    }
    
    private func getRouteTypeColor() -> Color {
        guard let routeTypeEnum = RouteType(rawValue: routeType) else {
            return .gray
        }
        return routeTypeEnum.color
    }
    
    private func getTransportModeIcon() -> String {
        guard let transportModeEnum = TransportMode(rawValue: transportMode) else {
            return "car"
        }
        return transportModeEnum.icon
    }
    
    private func getTransportModeColor() -> Color {
        guard let transportModeEnum = TransportMode(rawValue: transportMode) else {
            return .gray
        }
        return transportModeEnum.color
    }
}

// MARK: - Preview
#Preview {
    AddRouteView { _ in }
}

