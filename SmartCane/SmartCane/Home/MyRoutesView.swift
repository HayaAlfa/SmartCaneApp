//
//  MyRoutesView.swift
//  SmartCane
//
//  Created by Assistant on 12/19/24.
//

import SwiftUI

// MARK: - My Routes View
// This view allows users to save and manage familiar routes between locations
struct MyRoutesView: View {
    
    // MARK: - State Properties
    @State private var savedRoutes: [SavedRoute] = []
    @State private var showingAddRoute = false
    @State private var selectedRouteToDelete: SavedRoute?
    @State private var showingDeleteAlert = false
    
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            VStack {
                if savedRoutes.isEmpty {
                    emptyStateView
                } else {
                    routesListView
                }
            }
            .navigationTitle("My Routes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRoute = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRoute) {
                AddRouteView { newRoute in
                    savedRoutes.append(newRoute)
                    saveRoutes()
                }
            }
            .onAppear {
                loadRoutes()
            }
            .alert("Delete Route", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let route = selectedRouteToDelete {
                        deleteRoute(route)
                    }
                }
            } message: {
                if let route = selectedRouteToDelete {
                    Text("Are you sure you want to delete '\(route.name)'? This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Routes Saved")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save your familiar routes to get quick navigation assistance")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Add Your First Route") {
                showingAddRoute = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Routes List View
    private var routesListView: some View {
        List {
            ForEach(savedRoutes) { route in
                RouteRowView(
                    route: route,
                    onTap: {
                        // Action when route is tapped
                        SpeechManager.shared.speak(_text: "Route \(route.name) selected")
                    },
                    onDelete: {
                        selectedRouteToDelete = route
                        showingDeleteAlert = true
                    }
                )
            }
            .onDelete(perform: deleteRoutes)
        }
    }
    
    // MARK: - Helper Methods
    
    // Load saved routes from UserDefaults
    private func loadRoutes() {
        if let data = UserDefaults.standard.data(forKey: "savedRoutes"),
           let routes = try? JSONDecoder().decode([SavedRoute].self, from: data) {
            savedRoutes = routes
        }
    }
    
    // Save routes to UserDefaults
    private func saveRoutes() {
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: "savedRoutes")
        }
    }
    
    // Delete routes
    private func deleteRoutes(offsets: IndexSet) {
        savedRoutes.remove(atOffsets: offsets)
        saveRoutes()
    }
    
    // Delete a specific route
    private func deleteRoute(_ route: SavedRoute) {
        savedRoutes.removeAll { $0.id == route.id }
        saveRoutes()
        selectedRouteToDelete = nil
    }
}

// MARK: - Saved Route Model
struct SavedRoute: Identifiable, Codable {
    var id = UUID()
    let name: String
    let startLocation: SavedLocation
    let endLocation: SavedLocation
    let description: String
    let dateCreated: Date
    
    init(name: String, startLocation: SavedLocation, endLocation: SavedLocation, description: String) {
        self.name = name
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.description = description
        self.dateCreated = Date()
    }
}

// MARK: - Route Row View
struct RouteRowView: View {
    let route: SavedRoute
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Main content (tappable)
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(route.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        // Delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        Text(route.startLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "flag.circle.fill")
                            .foregroundColor(.red)
                        Text(route.endLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !route.description.isEmpty {
                        Text(route.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            
        }
    }
}

// MARK: - Add Route View
struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SavedRoute) -> Void
    
    @State private var routeName = ""
    @State private var selectedStartLocation: SavedLocation?
    @State private var selectedEndLocation: SavedLocation?
    @State private var description = ""
    @State private var showingStartLocationPicker = false
    @State private var showingEndLocationPicker = false
    @State private var savedLocations: [SavedLocation] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Route Details") {
                    TextField("Route Name", text: $routeName)
                    
                    // Start Location Picker
                    Button(action: {
                        showingStartLocationPicker = true
                    }) {
                        HStack {
                            Text("Start Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedStartLocation?.name ?? "Select Start Location")
                                .foregroundColor(selectedStartLocation != nil ? .secondary : .blue)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // End Location Picker
                    Button(action: {
                        showingEndLocationPicker = true
                    }) {
                        HStack {
                            Text("End Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(selectedEndLocation?.name ?? "Select End Location")
                                .foregroundColor(selectedEndLocation != nil ? .secondary : .blue)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Validation message
                    if selectedStartLocation != nil && selectedEndLocation != nil && selectedStartLocation?.id == selectedEndLocation?.id {
                        Text("Start and end locations must be different")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Description (Optional)") {
                    TextField("Add notes about this route...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
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
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingStartLocationPicker) {
                LocationPickerView(
                    savedLocations: savedLocations,
                    selectedLocation: $selectedStartLocation,
                    title: "Select Start Location"
                )
            }
            .sheet(isPresented: $showingEndLocationPicker) {
                LocationPickerView(
                    savedLocations: savedLocations,
                    selectedLocation: $selectedEndLocation,
                    title: "Select End Location"
                )
            }
            .onAppear {
                loadSavedLocations()
            }
        }
    }
    
    private var canSave: Bool {
        !routeName.isEmpty &&
        selectedStartLocation != nil &&
        selectedEndLocation != nil &&
        selectedStartLocation?.id != selectedEndLocation?.id
    }
    
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "SavedLocations"),
           let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = locations
        }
    }
    
    private func saveRoute() {
        guard let startLocation = selectedStartLocation,
              let endLocation = selectedEndLocation else {
            return
        }
        
        let newRoute = SavedRoute(
            name: routeName,
            startLocation: startLocation,
            endLocation: endLocation,
            description: description
        )
        onSave(newRoute)
        dismiss()
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    let savedLocations: [SavedLocation]
    @Binding var selectedLocation: SavedLocation?
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredLocations: [SavedLocation] {
        if searchText.isEmpty {
            return savedLocations
        } else {
            return savedLocations.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if savedLocations.isEmpty {
                    emptyStateView
                } else {
                    locationListView
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
            }
            .searchable(text: $searchText, prompt: "Search locations...")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Saved Locations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save some locations first to create routes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Go to Saved Locations") {
                dismiss()
                // Note: In a real app, you might want to navigate to the saved locations tab
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
    
    private var locationListView: some View {
        List(filteredLocations) { location in
            LocationPickerRowView(
                location: location,
                isSelected: selectedLocation?.id == location.id
            ) {
                selectedLocation = location
                dismiss()
            }
        }
    }
}

// MARK: - Location Picker Row View
struct LocationPickerRowView: View {
    let location: SavedLocation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search routes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    MyRoutesView()
}
