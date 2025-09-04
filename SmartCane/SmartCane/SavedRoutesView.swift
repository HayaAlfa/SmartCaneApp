import SwiftUI
import MapKit

struct SavedRoutesView: View {
    // MARK: - State Properties
    @State private var savedRoutes: [SimpleRoute] = []
    @State private var showingAddRoute = false
    @State private var searchText = ""
    @State private var selectedRouteType: String? = nil
    @State private var selectedTransportMode: String? = nil
    
    // MARK: - Computed Properties
    var filteredRoutes: [SimpleRoute] {
        var filtered = savedRoutes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by route type
        if let routeType = selectedRouteType {
            filtered = filtered.filter { $0.routeType == routeType }
        }
        
        // Filter by transport mode
        if let transportMode = selectedTransportMode {
            filtered = filtered.filter { $0.preferredTransportMode == transportMode }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterSection
                routesListSection
            }
            .navigationTitle("Saved Routes")
            .navigationBarTitleDisplayMode(.large)
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
                SimpleAddRouteView { newRoute in
                    savedRoutes.append(newRoute)
                    saveRoutes()
                }
            }
            .onAppear {
                loadRoutes()
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            searchBar
            filterButtons
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
                TextField("Search routes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }
    }
    
    // MARK: - Filter Buttons
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allRoutesButton
                routeTypeButtons
                transportModeButtons
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - All Routes Button
    private var allRoutesButton: some View {
        Button(action: {
            selectedRouteType = nil
            selectedTransportMode = nil
        }) {
            Text("All")
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedRouteType == nil && selectedTransportMode == nil ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(selectedRouteType == nil && selectedTransportMode == nil ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Route Type Buttons
    private var routeTypeButtons: some View {
        ForEach(RouteType.allCases, id: \.self) { routeType in
            Button(action: {
                selectedRouteType = selectedRouteType == routeType.rawValue ? nil : routeType.rawValue
            }) {
                HStack(spacing: 4) {
                    Image(systemName: routeType.icon)
                        .font(.caption)
                    Text(routeType.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedRouteType == routeType.rawValue ? routeType.color : Color.gray.opacity(0.3))
                .foregroundColor(selectedRouteType == routeType.rawValue ? .white : .primary)
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Transport Mode Buttons
    private var transportModeButtons: some View {
        ForEach(TransportMode.allCases, id: \.self) { transportMode in
            Button(action: {
                selectedTransportMode = selectedTransportMode == transportMode.rawValue ? nil : transportMode.rawValue
            }) {
                HStack(spacing: 4) {
                    Image(systemName: transportMode.icon)
                        .font(.caption)
                    Text(transportMode.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTransportMode == transportMode.rawValue ? transportMode.color : Color.gray.opacity(0.3))
                .foregroundColor(selectedTransportMode == transportMode.rawValue ? .white : .primary)
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Routes List Section
    private var routesListSection: some View {
        Group {
            if filteredRoutes.isEmpty {
                emptyStateView
            } else {
                routesList
            }
        }
    }
    
    // MARK: - Routes List
    private var routesList: some View {
        List {
            ForEach(filteredRoutes) { route in
                SimpleRouteRow(route: route) {
                    deleteRoute(route)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Saved Routes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create your first route to get started with navigation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddRoute = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Route")
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
    private func deleteRoute(_ route: SimpleRoute) {
        if let index = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            savedRoutes.remove(at: index)
            saveRoutes()
        }
    }
    
    private func saveRoutes() {
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: "savedRoutes")
        }
    }
    
    private func loadRoutes() {
        if let data = UserDefaults.standard.data(forKey: "savedRoutes"),
           let routes = try? JSONDecoder().decode([SimpleRoute].self, from: data) {
            savedRoutes = routes
        }
    }
}

// MARK: - Simple Data Models
// Using SimpleRoute and SimpleLocation from SimpleDataManager.swift

// MARK: - Route Type Enum
enum RouteType: String, CaseIterable {
    case daily = "Daily"
    case work = "Work"
    case shopping = "Shopping"
    case recreation = "Recreation"
    case emergency = "Emergency"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .daily: return "house.fill"
        case .work: return "building.2.fill"
        case .shopping: return "cart.fill"
        case .recreation: return "leaf.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .daily: return .blue
        case .work: return .green
        case .shopping: return .orange
        case .recreation: return .purple
        case .emergency: return .red
        case .custom: return .yellow
        }
    }
}

// MARK: - Transport Mode Enum
enum TransportMode: String, CaseIterable {
    case walking = "Walking"
    case wheelchair = "Wheelchair"
    case publicTransport = "Public Transport"
    case taxi = "Taxi"
    case car = "Car"
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .wheelchair: return "figure.roll"
        case .publicTransport: return "bus"
        case .taxi: return "car.fill"
        case .car: return "car"
        }
    }
    
    var color: Color {
        switch self {
        case .walking: return .green
        case .wheelchair: return .blue
        case .publicTransport: return .orange
        case .taxi: return .yellow
        case .car: return .purple
        }
    }
}

// MARK: - Simple Route Row Component
struct SimpleRouteRow: View {
    let route: SimpleRoute
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // MARK: - Route Icon
                VStack(spacing: 4) {
                    Image(systemName: getRouteTypeIcon())
                        .font(.title2)
                        .foregroundColor(getRouteTypeColor())
                        .frame(width: 40, height: 40)
                        .background(getRouteTypeColor().opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(route.routeType)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Route Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Origin to Destination
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(route.origin.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(route.destination.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Transport mode
                    HStack {
                        Image(systemName: getTransportModeIcon())
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(route.preferredTransportMode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Creation date
                    Text("Created \(route.dateCreated.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // MARK: - Action Buttons
                VStack(spacing: 8) {
                    // Delete route
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // MARK: - Route Notes (if any)
            if !route.notes.isEmpty {
                Text(route.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        
        // MARK: - Delete Alert
        .alert("Delete Route", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(route.name)'?")
        }
    }
    
    // MARK: - Helper Methods
    private func getRouteTypeIcon() -> String {
        guard let routeType = RouteType(rawValue: route.routeType) else {
            return "map"
        }
        return routeType.icon
    }
    
    private func getRouteTypeColor() -> Color {
        guard let routeType = RouteType(rawValue: route.routeType) else {
            return .gray
        }
        return routeType.color
    }
    
    private func getTransportModeIcon() -> String {
        guard let transportMode = TransportMode(rawValue: route.preferredTransportMode) else {
            return "car"
        }
        return transportMode.icon
    }
}

// MARK: - Simple Add Route View
struct SimpleAddRouteView: View {
    let onSave: (SimpleRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedOrigin: SimpleLocation?
    @State private var selectedDestination: SimpleLocation?
    @State private var selectedRouteType: RouteType = .daily
    @State private var selectedTransportMode: TransportMode = .walking
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Route Details") {
                    TextField("Route Name", text: $name)
                    
                    Picker("Route Type", selection: $selectedRouteType) {
                        ForEach(RouteType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Transport Mode", selection: $selectedTransportMode) {
                        ForEach(TransportMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveRoute() {
        // For now, create dummy locations - in a real app you'd pick from saved locations
        let origin = SimpleLocation(name: "Origin", address: "123 Start St", latitude: 0, longitude: 0)
        let destination = SimpleLocation(name: "Destination", address: "456 End Ave", latitude: 0, longitude: 0)
        
        let newRoute = SimpleRoute(
            name: name,
            origin: origin,
            destination: destination,
            routeType: selectedRouteType.rawValue,
            preferredTransportMode: selectedTransportMode.rawValue,
            notes: notes,
            dateCreated: Date()
        )
        
        onSave(newRoute)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    SavedRoutesView()
}
