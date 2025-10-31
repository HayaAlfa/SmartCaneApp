//
//  MyRoutesView.swift
//  SmartCane
//
//  Merged version (Haya + friend)
//

import SwiftUI
import AVFoundation

// MARK: - My Routes View
struct MyRoutesView: View {

    // MARK: - Environment & State
    @EnvironmentObject var dataService: SmartCaneDataService
    @State private var showingAddRoute = false
    @State private var selectedRouteToDelete: SavedRoute?
    @State private var showingDeleteAlert = false
    @State private var showStartPrompt = false
    @State private var routeToStart: SavedRoute?
    @Binding var selectedTab: Int
    
    // MARK: - Init
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    // MARK: - Computed Properties
    private var alertTitle: String {
        if let route = routeToStart {
            return "Start Navigation from \(route.name)?"
        }
        return "Start Navigation?"
    }
    
    private var deleteAlertTitle: String {
        if let route = selectedRouteToDelete {
            return "Delete Route from \(route.name)?"
        }
        return "Delete Route?"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if dataService.userRoutes.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(dataService.userRoutes) { route in
                            RouteRowView(
                                route: route,
                                onTap: { SpeechManager.shared.speak(_text: "Route \(route.name) selected") },
                                onDelete: {
                                    selectedRouteToDelete = route
                                    showingDeleteAlert = true
                                },
                                onPlay: {
                                    routeToStart = route
                                    prepareNavigationAndPrompt(for: route)
                                },
                                selectedTab: $selectedTab
                            )
                        }
                    }
                }
            }
            .navigationTitle("My Routes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRoute = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.headline)
                            Text("Add Route")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .sheet(isPresented: $showingAddRoute) {
                AddRouteView()
                    .environmentObject(dataService)
            }
            .onAppear {
                Task {
                    do {
                        try await dataService.fetchUserRoutes()
                    } catch {
                        print("❌ Failed to fetch routes:", error.localizedDescription)
                    }
                }
            }
            .alert(deleteAlertTitle, isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let route = selectedRouteToDelete {
                        Task {
                            do {
                                try await dataService.deleteUserRoute(route)
                            } catch {
                                print("❌ Failed to delete route:", error.localizedDescription)
                            }
                        }
                    }
                }
            }
            .alert(alertTitle, isPresented: $showStartPrompt) {
                Button("Cancel", role: .cancel) {
                    cancelNavigation()
                    routeToStart = nil
                }
                Button("Start") {
                    if let route = routeToStart {
                        startNavigation(for: route)
                    }
                    routeToStart = nil
                }
            }
        }
    }
    
    // MARK: - Navigation Functions
    private func startNavigation(for route: SavedRoute) {
        UserDefaults.standard.set(true, forKey: "AutoStartNavigation")
        selectedTab = 1
    }

    private func cancelNavigation() {
        let keys = ["NavigationStartLatitude", "NavigationStartLongitude", "NavigationEndLatitude", "NavigationEndLongitude", "AutoStartNavigation"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func prepareNavigationAndPrompt(for route: SavedRoute) {
        UserDefaults.standard.set(route.startLocation.latitude, forKey: "NavigationStartLatitude")
        UserDefaults.standard.set(route.startLocation.longitude, forKey: "NavigationStartLongitude")
        UserDefaults.standard.set(route.endLocation.latitude, forKey: "NavigationEndLatitude")
        UserDefaults.standard.set(route.endLocation.longitude, forKey: "NavigationEndLongitude")
        UserDefaults.standard.set(false, forKey: "AutoStartNavigation")
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Audio session error:", error)
        }
        
        SpeechManager.shared.speak(_text: "Route is ready.")
        showStartPrompt = true
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Routes Saved")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save your familiar routes to get quick navigation assistance.")
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
    let onPlay: () -> Void
    @Binding var selectedTab: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(route.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            GeometryReader { geo in
                HStack(spacing: 10) {
                    // Play button
                    Button {
                        onPlay()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: geo.size.width * 0.7)
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 44)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: geo.size.width * 0.28)
                }
            }
            .frame(height: 44)
            
            if !route.description.isEmpty {
                Text(route.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Add Route View
struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: SmartCaneDataService
    
    @State private var selectedStartLocation: SavedLocation?
    @State private var selectedEndLocation: SavedLocation?
    @State private var description = ""
    @State private var showingStartLocationPicker = false
    @State private var showingEndLocationPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Route Details") {
                    Button(action: { showingStartLocationPicker = true }) {
                        HStack {
                            Text(selectedStartLocation != nil ? selectedStartLocation!.name : "Select Start Location")
                                .foregroundColor(selectedStartLocation != nil ? .primary : .blue)
                            Spacer()
                            if selectedStartLocation != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button(action: { showingEndLocationPicker = true }) {
                        HStack {
                            Text(selectedEndLocation != nil ? selectedEndLocation!.name : "Select End Location")
                                .foregroundColor(selectedEndLocation != nil ? .primary : .blue)
                            Spacer()
                            if selectedEndLocation != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Description (Optional)") {
                    TextField("Add notes...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveRoute() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingStartLocationPicker) {
                LocationPickerView(
                    savedLocations: dataService.savedLocations,
                    selectedLocation: $selectedStartLocation,
                    title: "Select Start Location"
                )
            }
            .sheet(isPresented: $showingEndLocationPicker) {
                LocationPickerView(
                    savedLocations: dataService.savedLocations,
                    selectedLocation: $selectedEndLocation,
                    title: "Select End Location"
                )
            }
            .onAppear {
                Task {
                    try? await dataService.fetchUserLocations()
                }
            }
        }
    }
    
    private var canSave: Bool {
        selectedStartLocation != nil &&
        selectedEndLocation != nil &&
        selectedStartLocation?.id != selectedEndLocation?.id
    }
    
    private func saveRoute() {
        guard let start = selectedStartLocation, let end = selectedEndLocation else { return }
        let autoName = "\(start.name) to \(end.name)"
        let newRoute = SavedRoute(name: autoName, startLocation: start, endLocation: end, description: description)
        Task {
            try? await dataService.saveUserRoute(newRoute)
            try? await dataService.fetchUserRoutes()
            dismiss()
        }
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
                    Button("Cancel") { dismiss() }
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
    MyRoutesView(selectedTab: .constant(0))
        .environmentObject(SmartCaneDataService())
}
