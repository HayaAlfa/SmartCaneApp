import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/hayaalfakieh/Downloads/SmartCaneApp/SmartCane/SmartCane/SavedLocationsView.swift", line: 1)
import SwiftUI
import MapKit  // For opening locations in Maps app

// MARK: - Data Model for Saved Locations
// This struct defines what information we store for each saved location
struct SavedLocation: Identifiable, Codable {
    let id = UUID()                    // Unique identifier for each location
    var name: String                   // User-friendly name (e.g., "Home", "Work")
    var address: String                // Full address of the location
    var latitude: Double               // GPS latitude coordinate
    var longitude: Double              // GPS longitude coordinate
    var category: LocationCategory     // Type of location (home, work, etc.)
    var notes: String                  // Optional user notes about the location
    var dateAdded: Date                // When the location was saved
    
    // MARK: - Location Categories
    // Enum defines the different types of locations users can save
    enum LocationCategory: String, CaseIterable, Codable {
        case home = "Home"           // User's home address
        case work = "Work"           // User's workplace
        case favorite = "Favorite"   // User's favorite places
        case restaurant = "Restaurant" // Food establishments
        case store = "Store"         // Shopping locations
        case other = "Other"         // Miscellaneous places
        
        // MARK: - Category Icons
        // Each category has its own icon and color for visual distinction
        var icon: String {
            switch self {
            case .home: return __designTimeString("#29603_0", fallback: "house.fill")
            case .work: return __designTimeString("#29603_1", fallback: "building.2.fill")
            case .favorite: return __designTimeString("#29603_2", fallback: "heart.fill")
            case .restaurant: return __designTimeString("#29603_3", fallback: "fork.knife")
            case .store: return __designTimeString("#29603_4", fallback: "cart.fill")
            case .other: return __designTimeString("#29603_5", fallback: "mappin")
            }
        }
        
        // MARK: - Category Colors
        var color: Color {
            switch self {
            case .home: return .blue
            case .work: return .green
            case .favorite: return .red
            case .restaurant: return .orange
            case .store: return .purple
            case .other: return .gray
            }
        }
    }
}

struct SavedLocationsView: View {
    // MARK: - State Properties
    @State private var savedLocations: [SavedLocation] = []        // Array of all saved locations
    @State private var showingAddLocation = false                  // Controls add location sheet
    @State private var searchText = ""                             // Text for searching locations
    @State private var selectedCategory: SavedLocation.LocationCategory? = nil  // Filter by category
    
    // MARK: - Computed Property for Filtered Locations
    // This automatically filters locations based on search text and selected category
    var filteredLocations: [SavedLocation] {
        var filtered = savedLocations
        
        // Filter by search text (searches name, address, and notes)
        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText) ||
                location.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: __designTimeInteger("#29603_6", fallback: 0)) {
                // MARK: - Search and Filter Bar
                VStack(spacing: __designTimeInteger("#29603_7", fallback: 12)) {
                    HStack {
                        // MARK: - Search Input
                        HStack {
                            Image(systemName: __designTimeString("#29603_8", fallback: "magnifyingglass"))  // Search icon
                                .foregroundColor(.gray)
                            
                            // Text field for searching locations
                            TextField(__designTimeString("#29603_9", fallback: "Search locations..."), text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(.ultraThinMaterial)  // Translucent background
                        .cornerRadius(__designTimeInteger("#29603_10", fallback: 15))
                    }
                    
                    // MARK: - Category Filter Buttons
                    // Horizontal scrollable list of category filter buttons
                    ScrollView(.horizontal, showsIndicators: __designTimeBoolean("#29603_11", fallback: false)) {
                        HStack(spacing: __designTimeInteger("#29603_12", fallback: 12)) {
                            // "All" button to show all categories
                            Button(action: {
                                selectedCategory = nil  // Clear category filter
                            }) {
                                Text(__designTimeString("#29603_13", fallback: "All"))
                                    .font(.caption)
                                    .padding(.horizontal, __designTimeInteger("#29603_14", fallback: 16))
                                    .padding(.vertical, __designTimeInteger("#29603_15", fallback: 8))
                                    .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(__designTimeFloat("#29603_16", fallback: 0.3)))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .cornerRadius(__designTimeInteger("#29603_17", fallback: 20))
                            }
                            
                            // Category-specific filter buttons
                            ForEach(SavedLocation.LocationCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    // Toggle category selection (select if not selected, deselect if already selected)
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    HStack(spacing: __designTimeInteger("#29603_18", fallback: 4)) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, __designTimeInteger("#29603_19", fallback: 16))
                                    .padding(.vertical, __designTimeInteger("#29603_20", fallback: 8))
                                    .background(selectedCategory == category ? category.color : Color.gray.opacity(__designTimeFloat("#29603_21", fallback: 0.3)))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(__designTimeInteger("#29603_22", fallback: 20))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // MARK: - Locations List
                if filteredLocations.isEmpty {
                    // Show empty state when no locations match filters
                    emptyStateView
                } else {
                    // Show list of filtered locations
                    List {
                        ForEach(filteredLocations) { location in
                            SavedLocationRow(location: location) {
                                deleteLocation(location)  // Pass delete function to row
                            }
                        }
                    }
                    .listStyle(PlainListStyle())  // Remove default list styling
                }
            }
            .navigationTitle(__designTimeString("#29603_23", fallback: "Saved Locations"))  // Navigation bar title
            .navigationBarTitleDisplayMode(.large)  // Large title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Add button in top-right corner
                    Button(action: {
                        showingAddLocation = __designTimeBoolean("#29603_24", fallback: true)  // Show add location sheet
                    }) {
                        Image(systemName: __designTimeString("#29603_25", fallback: "plus"))
                    }
                }
            }
            // MARK: - Add Location Sheet
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    savedLocations.append(newLocation)  // Add new location to array
                    saveLocations()                      // Save to persistent storage
                }
            }
            .onAppear {
                loadLocations()  // Load saved locations when view appears
            }
        }
    }
    
    // MARK: - Empty State View
    // Shown when there are no saved locations or no results match filters
    private var emptyStateView: some View {
        VStack(spacing: __designTimeInteger("#29603_26", fallback: 20)) {
            Spacer()
            
            // Large icon to indicate empty state
            Image(systemName: __designTimeString("#29603_27", fallback: "mappin.slash"))
                .font(.system(size: __designTimeInteger("#29603_28", fallback: 60)))
                .foregroundColor(.gray)
            
            // Empty state title
            Text(__designTimeString("#29603_29", fallback: "No Saved Locations"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Helpful instruction text
            Text(__designTimeString("#29603_30", fallback: "Tap the + button to add your first location"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Quick action button
            Button(action: {
                showingAddLocation = __designTimeBoolean("#29603_31", fallback: true)
            }) {
                HStack {
                    Image(systemName: __designTimeString("#29603_32", fallback: "plus"))
                    Text(__designTimeString("#29603_33", fallback: "Add Location"))
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(__designTimeInteger("#29603_34", fallback: 10))
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Data Management Functions
    
    // Remove a location from the array
    private func deleteLocation(_ location: SavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations.remove(at: index)  // Remove from array
            saveLocations()                    // Save changes to storage
        }
    }
    
    // Save locations array to UserDefaults (persistent storage)
    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: __designTimeString("#29603_35", fallback: "SavedLocations"))
        }
    }
    
    // Load locations from UserDefaults (persistent storage)
    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: __designTimeString("#29603_36", fallback: "SavedLocations")),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = decoded
        }
    }
}

// MARK: - Individual Location Row Component
// This view represents each saved location in the list
struct SavedLocationRow: View {
    let location: SavedLocation           // The location data to display
    let onDelete: () -> Void             // Function to call when delete is tapped
    @State private var showingDeleteAlert = false  // Controls delete confirmation alert
    
    var body: some View {
        HStack(spacing: __designTimeInteger("#29603_37", fallback: 12)) {
            // MARK: - Category Icon
            // Shows the category icon with appropriate color
            Image(systemName: location.category.icon)
                .font(.title2)
                .foregroundColor(location.category.color)
                .frame(width: __designTimeInteger("#29603_38", fallback: 40), height: __designTimeInteger("#29603_39", fallback: 40))
                .background(location.category.color.opacity(__designTimeFloat("#29603_40", fallback: 0.1)))  // Subtle background
                .clipShape(Circle())
            
            // MARK: - Location Details
            VStack(alignment: .leading, spacing: __designTimeInteger("#29603_41", fallback: 4)) {
                Text(location.name)  // Location name (e.g., "Home", "Work")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(location.address)  // Full address
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Show notes if they exist
                if !location.notes.isEmpty {
                    Text(location.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(__designTimeInteger("#29603_42", fallback: 2))  // Limit to 2 lines to save space
                }
                
                // Show when location was added
                Text("Added \(location.dateAdded, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // MARK: - Action Buttons
            VStack(spacing: __designTimeInteger("#29603_43", fallback: 8)) {
                // Button to open location in Maps app
                Button(action: {
                    openInMaps()
                }) {
                    Image(systemName: __designTimeString("#29603_44", fallback: "arrow.triangle.turn.up.right.circle"))
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Button to delete location
                Button(action: {
                    showingDeleteAlert = __designTimeBoolean("#29603_45", fallback: true)  // Show delete confirmation
                }) {
                    Image(systemName: __designTimeString("#29603_46", fallback: "trash"))
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, __designTimeInteger("#29603_47", fallback: 8))
        
        // MARK: - Delete Confirmation Alert
        .alert(__designTimeString("#29603_48", fallback: "Delete Location"), isPresented: $showingDeleteAlert) {
            Button(__designTimeString("#29603_49", fallback: "Delete"), role: .destructive) {
                onDelete()  // Call the delete function passed from parent
            }
            Button(__designTimeString("#29603_50", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(location.name)'?")
        }
    }
    
    // MARK: - Open in Maps Function
    // Opens the selected location in the iOS Maps app
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: nil)  // Launch Maps app
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    SavedLocationsView()
}
