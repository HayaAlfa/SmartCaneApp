import SwiftUI
import MapKit  // For opening locations in Maps app

// MARK: - Data Model for Saved Locations
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
        
        // Filter by search text (searches name, address, and notes)
        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText) ||
                location.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterSection
                locationsListSection
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddLocation = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
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
            }
        }
    }
    
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
    
    // MARK: - Helper Methods
    
    // Delete a saved location using the data manager
    private func deleteLocation(_ location: SimpleSavedLocation) {
        dataManager.deleteSavedLocation(location)
    }
}

// MARK: - Individual Location Row Component
// This view represents each saved location in the list
struct SavedLocationRow: View {
    let location: SimpleSavedLocation           // The location data to display
    let onDelete: () -> Void             // Function to call when delete is tapped
    @State private var showingDeleteAlert = false  // Controls delete confirmation alert
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Category Icon
            // Shows the category icon with appropriate color
            let category = SimpleSavedLocation.LocationCategory(rawValue: location.category) ?? .other
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.1))  // Subtle background
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
