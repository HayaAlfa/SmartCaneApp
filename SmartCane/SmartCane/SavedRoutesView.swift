import SwiftUI
import MapKit

struct SavedRoutesView: View {
    // MARK: - State Properties
    @StateObject private var dataManager = TempDataManager.shared
    @State private var showingAddRoute = false
    @State private var searchText = ""
    @State private var selectedRouteType: String? = nil
    @State private var selectedTransportMode: String? = nil
    
    // MARK: - Computed Properties
    var filteredRoutes: [TempSavedRoute] {
        var filtered = dataManager.savedRoutes
        
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
                // MARK: - Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        // MARK: - Search Input
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
                    
                    // MARK: - Filter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All routes filter
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
                            
                            // Route type filters
                            ForEach(RouteType.allCases, id: \.self) { routeType in
                                Button(action: {
                                    selectedRouteType = selectedRouteType == routeType ? nil : routeType.rawValue
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
                            
                            // Transport mode filters
                            ForEach(TransportMode.allCases, id: \.self) { transportMode in
                                Button(action: {
                                    selectedTransportMode = selectedTransportMode == transportMode ? nil : transportMode.rawValue
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
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // MARK: - Routes List
                if filteredRoutes.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredRoutes) { route in
                            SavedRouteRow(route: route) {
                                deleteRoute(route)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
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
                AddRouteView { newRoute in
                    // Route is automatically saved by CoreDataManager
                }
            }
        }
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
    private func deleteRoute(_ route: TempSavedRoute) {
        if let index = dataManager.savedRoutes.firstIndex(where: { $0.id == route.id }) {
            dataManager.savedRoutes.remove(at: index)
            dataManager.saveData()
        }
    }
}

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

// MARK: - Saved Route Row Component
struct SavedRouteRow: View {
    let route: TempSavedRoute
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    @State private var showingRouteDetails = false
    
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
                    // View route details
                    Button(action: {
                        showingRouteDetails = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
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
        
        // MARK: - Alerts and Sheets
        .alert("Delete Route", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(route.name)'?")
        }
        .sheet(isPresented: $showingRouteDetails) {
            RouteDetailsView(route: route)
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

// MARK: - Route Details View
struct RouteDetailsView: View {
    let route: TempSavedRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Route Header
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(route.name ?? "Unnamed Route")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Created \(route.dateCreated.formatted(date: .complete, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    
                    // MARK: - Route Information
                    VStack(alignment: .leading, spacing: 16) {
                        // Route Type
                        InfoRow(title: "Route Type", value: route.routeType, icon: "map")
                        
                        // Transport Mode
                        InfoRow(title: "Transport Mode", value: route.preferredTransportMode, icon: "car")
                        
                        // Origin
                        InfoRow(title: "Origin", value: route.origin.name, icon: "circle.fill", color: .green)
                        
                        // Destination
                        InfoRow(title: "Destination", value: route.destination.name, icon: "mappin.circle.fill", color: .red)
                        
                        // Notes
                        if !route.notes.isEmpty {
                            InfoRow(title: "Notes", value: route.notes, icon: "note.text")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(15)
                    
                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // TODO: Implement route navigation
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Start Navigation")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // TODO: Implement route sharing
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    SavedRoutesView()
}

