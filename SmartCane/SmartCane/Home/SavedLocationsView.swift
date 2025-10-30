import SwiftUI
import MapKit  // For opening locations in Maps app

// MARK: - Data Model for Saved Locations
// This struct defines what information we store for each saved location
struct SavedLocation: Identifiable, Codable {
    var id = UUID()                    // Unique identifier for each location
    var name: String                   // User-friendly name (e.g., "Home", "Work")
    var address: String                // Full address of the location
    var latitude: Double               // GPS latitude coordinate
    var longitude: Double              // GPS longitude coordinate
    var notes: String                  // Optional user notes about the location
    var created_at: Date                // When the location was saved
}

struct SavedLocationsView: View {
    // MARK: - State Properties
    @EnvironmentObject var dataService: SmartCaneDataService
    
    @State private var showingAddLocation = false                  // Controls add location sheet
    @Binding var selectedTab: Int                                  // Binding to control tab selection
    
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Locations List
                if dataService.savedLocations.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(dataService.savedLocations) { location in
                            SavedLocationRow(
                                location: location,
                                selectedTab: $selectedTab,
                                onDelete: {
                                    Task {
                                        do {
                                            try await dataService.deleteUserLocation(location)
                                        } catch {
                                            print("❌ Failed to delete location:", error)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

            }
            .navigationTitle("Saved Locations")  // Navigation bar title
            .navigationBarTitleDisplayMode(.large)  // Large title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Add button in top-right corner
                    Button(action: {
                        showingAddLocation = true  // Show add location sheet
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // MARK: - Add Location Sheet
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView { newLocation in
                    Task {
                        do {
                            try await dataService.saveUserLocation(newLocation)
                            try await dataService.fetchUserLocations()
                        } catch {
                            print("❌ Failed to save location:", error)
                        }
                    }
                }
            }

            .onAppear {
                Task {
                    do {
                        try await dataService.fetchUserLocations()
                    } catch {
                        print("❌ Failed to fetch locations:", error)
                    }
                }
            }
        }
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
    

    
    
}

// MARK: - Individual Location Row Component
// This view represents each saved location in the list

struct SavedLocationRow: View {
    let location: SavedLocation           // The location data to display
    @Binding var selectedTab: Int        // Binding to control tab selection
    let onDelete: () -> Void             // Function to call when delete is tapped
    @State private var showingDeleteAlert = false  // Controls delete confirmation alert
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Location Icon
            // Shows a simple location pin icon for all saved locations
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))  // Subtle blue background
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
                Text("Added \(location.created_at, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // MARK: - Action Buttons
            HStack(spacing: 16) {
                // Button to show location on app's map
                Button(action: {
                    print("🗺️ Map button tapped for: \(location.name)")
                    // Switch to Map tab (index 1) and center on this location
                    selectedTab = 1
                    // Store location coordinates for map to use
                    UserDefaults.standard.set(location.latitude, forKey: "MapCenterLatitude")
                    UserDefaults.standard.set(location.longitude, forKey: "MapCenterLongitude")
                    UserDefaults.standard.set(location.name, forKey: "MapCenterName")
                }) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Button to delete location
                Button(action: {
                    print("🗑️ Delete button tapped for: \(location.name)")
                    showingDeleteAlert = true  // Show delete confirmation
                }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
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
    
}


// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    SavedLocationsView(selectedTab: .constant(0))
        .environmentObject(SmartCaneDataService())
}
