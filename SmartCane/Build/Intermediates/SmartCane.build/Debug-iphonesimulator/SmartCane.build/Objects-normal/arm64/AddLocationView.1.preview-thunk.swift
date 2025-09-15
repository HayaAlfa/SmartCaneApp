import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/AddLocationView.swift", line: 1)
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
    @State private var selectedCategory: SavedLocation.LocationCategory = .other  // Type of location
    @State private var notes = ""                   // Optional user notes about the location
    @State private var useCurrentLocation = false   // Whether to use GPS coordinates
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Location Details Section
                // Main form section for location information
                Section(__designTimeString("#28924_0", fallback: "Location Details")) {
                    // MARK: - Location Name Input
                    // Text field for user to enter a friendly name
                    TextField(__designTimeString("#28924_1", fallback: "Location Name"), text: $name)
                        .textContentType(.name)  // iOS will suggest names from contacts
                    
                    // MARK: - Address Input
                    // Text field for the full address
                    TextField(__designTimeString("#28924_2", fallback: "Address"), text: $address)
                        .textContentType(.fullStreetAddress)  // iOS will suggest addresses
                    
                    // MARK: - Category Picker
                    // Dropdown picker for selecting location category
                    Picker(__designTimeString("#28924_3", fallback: "Category"), selection: $selectedCategory) {
                        // Loop through all available categories
                        ForEach(SavedLocation.LocationCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)  // Show category icon
                                    .foregroundColor(category.color)
                                Text(category.rawValue)          // Show category name
                            }
                            .tag(category)  // This value is stored when selected
                        }
                    }
                    
                    // MARK: - Current Location Toggle
                    // Switch to automatically use current GPS coordinates
                    Toggle(__designTimeString("#28924_4", fallback: "Use Current Location"), isOn: $useCurrentLocation)
                        .onChange(of: useCurrentLocation) { newValue in
                            if newValue {
                                // When enabled, automatically fill in current address
                                address = locationManager.getCurrentLocationString()
                            }
                        }
                }
                
                // MARK: - Additional Information Section
                // Optional section for extra details
                Section(__designTimeString("#28924_5", fallback: "Additional Information")) {
                    // MARK: - Notes Input
                    // Multi-line text field for user notes
                    TextField(__designTimeString("#28924_6", fallback: "Notes (Optional)"), text: $notes, axis: .vertical)
                        .lineLimit(__designTimeInteger("#28924_7", fallback: 3)...__designTimeInteger("#28924_8", fallback: 6))  // Allow 3-6 lines of text
                }
                
                // MARK: - Current Location Details Section
                // Shows GPS coordinates when "Use Current Location" is enabled
                if useCurrentLocation {
                    Section(__designTimeString("#28924_9", fallback: "Current Location")) {
                        // MARK: - Latitude Display
                        HStack {
                            Text(__designTimeString("#28924_10", fallback: "Latitude:"))
                            Spacer()
                            Text(String(format: __designTimeString("#28924_11", fallback: "%.6f"), locationManager.region.center.latitude))
                                .foregroundColor(.secondary)
                        }
                        
                        // MARK: - Longitude Display
                        HStack {
                            Text(__designTimeString("#28924_12", fallback: "Longitude:"))
                            Spacer()
                            Text(String(format: __designTimeString("#28924_13", fallback: "%.6f"), locationManager.region.center.longitude))
                                .foregroundColor(.secondary)
                        }
                        
                        // MARK: - GPS Accuracy Display
                        HStack {
                            Text(__designTimeString("#28924_14", fallback: "Accuracy:"))
                            Spacer()
                            Text(locationManager.getLocationAccuracy())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(__designTimeString("#28924_15", fallback: "Add Location"))  // Navigation bar title
            .navigationBarTitleDisplayMode(.inline)  // Inline title style
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // MARK: - Cancel Button
                    // Button to dismiss the sheet without saving
                    Button(__designTimeString("#28924_16", fallback: "Cancel")) {
                        dismiss()  // Close the sheet
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Save Button
                    // Button to save the new location
                    Button(__designTimeString("#28924_17", fallback: "Save")) {
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
            latitude: useCurrentLocation ? locationManager.region.center.latitude : __designTimeFloat("#28924_18", fallback: 0.0),   // GPS latitude if enabled
            longitude: useCurrentLocation ? locationManager.region.center.longitude : __designTimeFloat("#28924_19", fallback: 0.0), // GPS longitude if enabled
            category: selectedCategory,    // Selected category
            notes: notes,                  // User-entered notes
            dateAdded: Date()              // Current timestamp
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
