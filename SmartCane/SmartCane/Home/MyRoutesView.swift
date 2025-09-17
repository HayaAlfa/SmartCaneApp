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
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    private var filteredRoutes: [SavedRoute] {
        if searchText.isEmpty {
            return savedRoutes
        } else {
            return savedRoutes.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.startLocation.localizedCaseInsensitiveContains(searchText) ||
                route.endLocation.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
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
        VStack {
            // Search Bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            // Routes List
            List {
                ForEach(filteredRoutes) { route in
                    RouteRowView(route: route) {
                        // Action when route is tapped
                        SpeechManager.shared.speak(_text: "Route to \(route.endLocation) selected")
                    }
                }
                .onDelete(perform: deleteRoutes)
            }
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
}

// MARK: - Saved Route Model
struct SavedRoute: Identifiable, Codable {
    var id = UUID()
    let name: String
    let startLocation: String
    let endLocation: String
    let description: String
    let dateCreated: Date
    
    init(name: String, startLocation: String, endLocation: String, description: String) {
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
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(route.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(route.startLocation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "flag.circle.fill")
                        .foregroundColor(.red)
                    Text(route.endLocation)
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

// MARK: - Add Route View
struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SavedRoute) -> Void
    
    @State private var routeName = ""
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Route Details") {
                    TextField("Route Name", text: $routeName)
                    TextField("Start Location", text: $startLocation)
                    TextField("End Location", text: $endLocation)
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
                    .disabled(routeName.isEmpty || startLocation.isEmpty || endLocation.isEmpty)
                }
            }
        }
    }
    
    private func saveRoute() {
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
