//
//  MyRoutesView.swift
//  SmartCane
//
//  Created by Assistant on 12/19/24.
//

import SwiftUI
import Speech

// MARK: - My Routes View
// This view allows users to save and manage familiar routes between locations
struct MyRoutesView: View {
    
    // MARK: - State Properties
    @State private var savedRoutes: [SavedRoute] = []
    @State private var showingAddRoute = false
    @State private var selectedRouteToDelete: SavedRoute?
    @State private var showingDeleteAlert = false
    @Binding var selectedTab: Int
    
    
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRoute = true
                    }) {
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
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    },
                    selectedTab: $selectedTab
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
    @Binding var selectedTab: Int
    @State private var showStartPrompt = false
    // Voice recognition for Start/Cancel while staying on this screen
    @State private var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @State private var audioEngine: AVAudioEngine = AVAudioEngine()
    @State private var recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    var body: some View {
        HStack {
            // Main content (tappable)
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(route.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                       
                    }
                    
                    GeometryReader { geo in
                        HStack(spacing: 10) {
                            // Play button (occupies ~70%)
                            Button(action: {
                                prepareNavigationAndPrompt()
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.headline)
                                    Text("Play")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .frame(height: 44)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: geo.size.width * 0.7)

                            // Trash button (occupies <30%)
                            Button(action: onDelete) {
                                Image(systemName: "trash.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .frame(height: 44)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .alert("Start Navigation?", isPresented: $showStartPrompt) {
            Button("Cancel", role: .cancel) {
                cancelNavigation()
                stopVoicePromptListening()
            }
            Button("Start") {
                startNavigation()
                stopVoicePromptListening()
            }
        } message: {
            Text("Say 'start' or 'cancel', or use the buttons below.")
        }
        .onChange(of: showStartPrompt) { _, isShown in
            if isShown {
                // Delay listening so TTS prompt is not captured and is audible
                requestSpeechAuthIfNeededAndStart(startAfter: 1.8)
            } else {
                stopVoicePromptListening()
            }
        }
    }
    
    // MARK: - Navigation Function
    private func startNavigation() {
        // Auto-start flag set by Start action
        UserDefaults.standard.set(true, forKey: "AutoStartNavigation")
        // Switch to Map tab (assuming Map is tab index 1)
        selectedTab = 1
    }

    private func cancelNavigation() {
        // Clear any previously stored coordinates and flags
        UserDefaults.standard.removeObject(forKey: "NavigationStartLatitude")
        UserDefaults.standard.removeObject(forKey: "NavigationStartLongitude")
        UserDefaults.standard.removeObject(forKey: "NavigationEndLatitude")
        UserDefaults.standard.removeObject(forKey: "NavigationEndLongitude")
        UserDefaults.standard.removeObject(forKey: "AutoStartNavigation")
    }

    private func prepareNavigationAndPrompt() {
        // Store coordinates for MapView to pick up, but do not switch tabs yet
        UserDefaults.standard.set(route.startLocation.latitude, forKey: "NavigationStartLatitude")
        UserDefaults.standard.set(route.startLocation.longitude, forKey: "NavigationStartLongitude")
        UserDefaults.standard.set(route.endLocation.latitude, forKey: "NavigationEndLatitude")
        UserDefaults.standard.set(route.endLocation.longitude, forKey: "NavigationEndLongitude")
        UserDefaults.standard.set(false, forKey: "AutoStartNavigation")
        // Ensure playback session so TTS is audible before mic starts (subsequently overridden in startVoicePromptListening)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Could not set playback session for prompt: \(error)")
        }
        // Voice prompt for accessibility (always speak on every Play)
        print("🔊 Prompt: Route is ready. Say start or cancel…")
        SpeechManager.shared.speak(_text: "Route is ready. Say start or cancel, or use the buttons.")
        // Show start/cancel prompt (stays in My Routes view)
        showStartPrompt = true
    }

    // MARK: - Voice Recognition (simple 'start'/'cancel')
    private func requestSpeechAuthIfNeededAndStart(startAfter delay: TimeInterval = 0.0) {
        let current = SFSpeechRecognizer.authorizationStatus()
        if current == .authorized {
            speechAuthStatus = .authorized
            print("🎙️ Speech auth status: authorized (cached)")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                startVoicePromptListening()
            }
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechAuthStatus = status
                print("🎙️ Speech auth status: \(status.rawValue)")
                if status == .authorized {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.startVoicePromptListening()
                    }
                } else {
                    print("⚠️ Speech not authorized; cannot listen for start/cancel")
                }
            }
        }
    }

    private func startVoicePromptListening() {
        guard speechAuthStatus == .authorized else {
            print("⚠️ Speech not authorized; cannot listen for start/cancel")
            return
        }
        stopVoicePromptListening()

        // Configure audio session for play+record so prompt audio remains audible
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Failed to configure audio session for recording: \(error)")
        }

        // Fresh engine per start to avoid stale taps/formats
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        // Install tap with nil format to let CoreAudio select the correct hardware format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do { try audioEngine.start() } catch {
            print("❌ Failed to start audioEngine: \(error)")
        }
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let text = result?.bestTranscription.formattedString.lowercased() {
                if text.contains("start") {
                    print("✅ Recognized 'start' in MyRoutes — starting navigation")
                    startNavigation()
                    stopVoicePromptListening()
                    showStartPrompt = false
                } else if text.contains("cancel") || text.contains("stop") {
                    print("✅ Recognized 'cancel' in MyRoutes — cancelling")
                    cancelNavigation()
                    stopVoicePromptListening()
                    showStartPrompt = false
                }
            }
            if let error = error {
                print("❌ Speech recognition error (MyRoutes): \(error.localizedDescription)")
                stopVoicePromptListening()
            }
        }
        print("🎙️ Listening for 'start'/'cancel'…")
    }

    private func stopVoicePromptListening() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            audioEngine.reset()
        }
        recognitionTask?.cancel(); recognitionTask = nil
        recognitionRequest?.endAudio(); recognitionRequest = nil
        // Deactivate session to release mic when done
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // ignore
        }
    }
}

// MARK: - Add Route View
struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SavedRoute) -> Void
    
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
        
        // Auto-generate route name: "<Start> to <End>"
        let autoName = "\(startLocation.name) to \(endLocation.name)"
        let newRoute = SavedRoute(
            name: autoName,
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
    MyRoutesView(selectedTab: .constant(0))
}
