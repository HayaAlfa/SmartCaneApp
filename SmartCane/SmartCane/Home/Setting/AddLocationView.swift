import SwiftUI
import MapKit  // For accessing location services and coordinates

struct AddLocationView: View {
    // MARK: - Properties
    // This closure is called when the user saves a new location
    let onSave: (SavedLocation) -> Void
    
    // MARK: - Environment
    // @Environment provides access to the current view's environment
    @Environment(\.dismiss) private var dismiss  // Used to close the sheet
    
    // MARK: - State Objects
    // @StateObject creates a persistent object that survives view updates
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - State Properties
    // @State properties are used for data that can change and trigger UI updates
    @State private var name = ""                    // Location name (e.g., "Home", "Work")
    // Address removed; we capture coordinates directly
    @State private var notes = ""                   // Optional user notes about the location
    @State private var useCurrentLocation = false   // Whether to use GPS coordinates
    @State private var latitudeInput = ""           // Manual latitude input
    @State private var longitudeInput = ""          // Manual longitude input
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Location Details Section
                // Main form section for location information
                Section("Location Details") {
                    // MARK: - Location Name Input
                    // Text field for user to enter a friendly name
                    TextField("Location Name", text: $name)
                        .textContentType(.name)  // iOS will suggest names from contacts
                    
                    // MARK: - Current Location Toggle
                    // Switch to automatically use current GPS coordinates
                    Toggle("Use Current Location", isOn: $useCurrentLocation)
                        .onChange(of: useCurrentLocation) {
                            if useCurrentLocation {
                                if let loc = locationManager.currentLocation {
                                    latitudeInput = String(format: "%.6f", loc.coordinate.latitude)
                                    longitudeInput = String(format: "%.6f", loc.coordinate.longitude)
                                }
                            }
                        }

                    // Manual coordinate inputs (enabled when not using current location)
                    TextField("Latitude (-90 to 90)", text: $latitudeInput)
                        .keyboardType(.decimalPad)
                        .disabled(useCurrentLocation)
                    TextField("Longitude (-180 to 180)", text: $longitudeInput)
                        .keyboardType(.decimalPad)
                        .disabled(useCurrentLocation)
                }
                
                // MARK: - Additional Information Section
                // Optional section for extra details
                Section("Additional Information") {
                    // MARK: - Notes Input
                    // Multi-line text field for user notes
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)  // Allow 3-6 lines of text
                }
                
                // MARK: - Current Location Details Section
                // Shows GPS coordinates when "Use Current Location" is enabled
                if useCurrentLocation {
                    Section("Current Location") {
                        // MARK: - Latitude Display
                        HStack {
                            Text("Latitude:")
                            Spacer()
                            Text(String(format: "%.6f", locationManager.region.center.latitude))
                                .foregroundColor(.secondary)
                        }
                        
                        // MARK: - Longitude Display
                        HStack {
                            Text("Longitude:")
                            Spacer()
                            Text(String(format: "%.6f", locationManager.region.center.longitude))
                                .foregroundColor(.secondary)
                        }
                        
                        // MARK: - GPS Accuracy Display
                        HStack {
                            Text("Accuracy:")
                            Spacer()
                            Text(locationManager.getLocationAccuracy())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Location")  // Navigation bar title
            .navigationBarTitleDisplayMode(.inline)  // Inline title style
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // MARK: - Cancel Button
                    // Button to dismiss the sheet without saving
                    Button("Cancel") {
                        dismiss()  // Close the sheet
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Save Button
                    // Button to save the new location
                    Button("Save") {
                        saveLocation()  // Call the save function
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                // MARK: - View Setup
                // This runs when the view appears on screen
                if let loc = locationManager.currentLocation {
                    latitudeInput = String(format: "%.6f", loc.coordinate.latitude)
                    longitudeInput = String(format: "%.6f", loc.coordinate.longitude)
                }
            }
            .alert("Invalid Coordinates", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Save Location Function
    // Creates a new SavedLocation and calls the onSave closure
    private func saveLocation() {
        // Determine coordinates
        var lat: Double?
        var lon: Double?
        if useCurrentLocation, let loc = locationManager.currentLocation {
            lat = loc.coordinate.latitude
            lon = loc.coordinate.longitude
        } else {
            lat = Double(latitudeInput.trimmingCharacters(in: .whitespaces))
            lon = Double(longitudeInput.trimmingCharacters(in: .whitespaces))
        }
        // Validate presence
        guard let latitude = lat, let longitude = lon else {
            validationMessage = "Please enter valid numeric latitude and longitude."
            showValidationAlert = true
            return
        }
        // Validate ranges
        guard (-90.0...90.0).contains(latitude) else {
            validationMessage = "Latitude must be between -90 and 90."
            showValidationAlert = true
            return
        }
        guard (-180.0...180.0).contains(longitude) else {
            validationMessage = "Longitude must be between -180 and 180."
            showValidationAlert = true
            return
        }
        // Create location
        let newLocation = SavedLocation(
            name: name,
            address: "", // Address no longer captured
            latitude: latitude,
            longitude: longitude,
            notes: notes,
            dateAdded: Date()
        )
        onSave(newLocation)
        dismiss()
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    AddLocationView { _ in }
}
