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
    @State private var address = ""                 // Full address of the location
    @State private var notes = ""                   // Optional user notes about the location
    @State private var useCurrentLocation = false   // Whether to use GPS coordinates
    
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
                    
                    // MARK: - Address Input
                    // Text field for the full address
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)  // iOS will suggest addresses
                    
                    
                    // MARK: - Current Location Toggle
                    // Switch to automatically use current GPS coordinates
                    Toggle("Use Current Location", isOn: $useCurrentLocation)
                        .onChange(of: useCurrentLocation) {
                            if useCurrentLocation {
                                // When enabled, automatically fill in current address
                                address = locationManager.getCurrentLocationString()
                            }
                        }
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
                    .disabled(name.isEmpty || address.isEmpty)  // Disable if required fields are empty
                }
            }
            .onAppear {
                // MARK: - View Setup
                // This runs when the view appears on screen
                if locationManager.currentLocation != nil {
                    // If we have a current location, pre-fill the address
                    address = locationManager.getCurrentLocationString()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Save Location Function
    // Creates a new SavedLocation and calls the onSave closure
    private func saveLocation() {
        // Create a new location object with the form data
        let newLocation = SavedLocation(
            name: name,                    // User-entered name
            address: address,              // User-entered address
            latitude: useCurrentLocation ? locationManager.region.center.latitude : 0.0,   // GPS latitude if enabled
            longitude: useCurrentLocation ? locationManager.region.center.longitude : 0.0, // GPS longitude if enabled
            notes: notes,                  // User-entered notes
            created_at: Date()            // Current timestamp
        )
        
        // Call the onSave closure passed from the parent view
        onSave(newLocation)
        
        // Close the sheet
        dismiss()
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    AddLocationView { _ in }
    
}
