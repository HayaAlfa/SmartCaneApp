import SwiftUI
import MapKit  // For opening locations in Maps app

// MARK: - Data Model for Saved Locations
<<<<<<< HEAD
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
            case .home: return "house.fill"
            case .work: return "building.2.fill"
            case .favorite: return "heart.fill"
            case .restaurant: return "fork.knife"
            case .store: return "cart.fill"
            case .other: return "mappin"
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
=======
// Using SimpleSavedLocation from SimpleDataManager.swift

struct SavedLocationsView: View {
    // MARK: - State Properties
    // These properties control the UI state and store user data
    @StateObject private var dataManager = SimpleDataManager.shared  // Simple data manager
    @State private var showingAddLocation = false                  // Controls add location sheet
    @State private var searchText = ""                             // Text for searching locations
    @State private var selectedCategory: String = "All"            // Filter by category
    
    // MARK: - Computed Property for Filtered Locations
    // This automatically filters locations based on search text and selected category
    var filteredLocations: [SimpleSavedLocation] {
        var filtered = dataManager.savedLocations
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
        
        // Filter by search text (searches name, address, and notes)
        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText) ||
                location.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected category
<<<<<<< HEAD
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
=======
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
<<<<<<< HEAD
                // MARK: - Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        // MARK: - Search Input
                        HStack {
                            Image(systemName: "magnifyingglass")  // Search icon
                                .foregroundColor(.gray)
                            
                            // Text field for searching locations
                            TextField("Search locations...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(.ultraThinMaterial)  // Translucent background
                        .cornerRadius(15)
                    }
                    
                    // MARK: - Category Filter Buttons
                    // Horizontal scrollable list of category filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // "All" button to show all categories
                            Button(action: {
                                selectedCategory = nil  // Clear category filter
                            }) {
                                Text("All")
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            
                            // Category-specific filter buttons
                            ForEach(SavedLocation.LocationCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    // Toggle category selection (select if not selected, deselect if already selected)
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? category.color : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
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
            .navigationTitle("Saved Locations")  // Navigation bar title
            .navigationBarTitleDisplayMode(.large)  // Large title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Add button in top-right corner
                    Button(action: {
                        showingAddLocation = true  // Show add location sheet
=======
                searchAndFilterSection
                locationsListSection
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddLocation = true
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
<<<<<<< HEAD
            // MARK: - Add Location Sheet
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    savedLocations.append(newLocation)  // Add new location to array
                    saveLocations()                      // Save to persistent storage
                }
            }
            .onAppear {
                loadLocations()  // Load saved locations when view appears
=======
            .sheet(isPresented: $showingAddLocation) {
                SimpleAddLocationView { newLocation in
                    dataManager.addSavedLocation(newLocation)
                }
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            searchBar
            categoryFilters
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
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
    }
    
    // MARK: - Category Filters
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allCategoriesButton
                categoryButtons
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - All Categories Button
    private var allCategoriesButton: some View {
        Button(action: {
            selectedCategory = "All"
        }) {
            Text("All")
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategory == "All" ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(selectedCategory == "All" ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Category Buttons
    private var categoryButtons: some View {
        ForEach(SimpleSavedLocation.LocationCategory.allCases, id: \.self) { category in
            Button(action: {
                selectedCategory = selectedCategory == category.rawValue ? "All" : category.rawValue
            }) {
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedCategory == category.rawValue ? category.color : Color.gray.opacity(0.3))
                .foregroundColor(selectedCategory == category.rawValue ? .white : .primary)
                .cornerRadius(20)
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
            }
        }
    }
    
<<<<<<< HEAD
=======
    // MARK: - Locations List Section
    private var locationsListSection: some View {
        Group {
            if filteredLocations.isEmpty {
                emptyStateView
            } else {
                locationsList
            }
        }
    }
    
    // MARK: - Locations List
    private var locationsList: some View {
        List {
            ForEach(filteredLocations) { location in
                SavedLocationRow(location: location) {
                    deleteLocation(location)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
    // MARK: - Empty State View
    // Shown when there are no saved locations or no results match filters
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Large icon to indicate empty state
            Image(systemName: "mappin.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            // Empty state title
            Text("No Saved Locations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Helpful instruction text
            Text("Tap the + button to add your first location")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Quick action button
            Button(action: {
                showingAddLocation = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Location")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
    
<<<<<<< HEAD
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
            UserDefaults.standard.set(encoded, forKey: "SavedLocations")
        }
    }
    
    // Load locations from UserDefaults (persistent storage)
    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: "SavedLocations"),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = decoded
        }
=======
    // MARK: - Helper Methods
    
    // Delete a saved location using the data manager
    private func deleteLocation(_ location: SimpleSavedLocation) {
        dataManager.deleteSavedLocation(location)
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
    }
}

// MARK: - Individual Location Row Component
// This view represents each saved location in the list
struct SavedLocationRow: View {
<<<<<<< HEAD
    let location: SavedLocation           // The location data to display
=======
    let location: SimpleSavedLocation           // The location data to display
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
    let onDelete: () -> Void             // Function to call when delete is tapped
    @State private var showingDeleteAlert = false  // Controls delete confirmation alert
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Category Icon
            // Shows the category icon with appropriate color
<<<<<<< HEAD
            Image(systemName: location.category.icon)
                .font(.title2)
                .foregroundColor(location.category.color)
                .frame(width: 40, height: 40)
                .background(location.category.color.opacity(0.1))  // Subtle background
=======
            let category = SimpleSavedLocation.LocationCategory(rawValue: location.category) ?? .other
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.1))  // Subtle background
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                .clipShape(Circle())
            
            // MARK: - Location Details
            VStack(alignment: .leading, spacing: 4) {
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
                        .lineLimit(2)  // Limit to 2 lines to save space
                }
                
                // Show when location was added
                Text("Added \(location.dateAdded, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // MARK: - Action Buttons
            VStack(spacing: 8) {
                // Button to open location in Maps app
                Button(action: {
                    openInMaps()
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Button to delete location
                Button(action: {
                    showingDeleteAlert = true  // Show delete confirmation
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        
        // MARK: - Delete Confirmation Alert
        .alert("Delete Location", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()  // Call the delete function passed from parent
            }
            Button("Cancel", role: .cancel) { }
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
