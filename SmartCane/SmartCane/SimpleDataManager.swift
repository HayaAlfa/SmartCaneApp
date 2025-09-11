import Foundation
import SwiftUI

// MARK: - Simple Data Manager
// This class manages all local data storage using UserDefaults instead of Core Data
// Much simpler and more stable than Core Data
class SimpleDataManager: ObservableObject {
    static let shared = SimpleDataManager()
    
    // MARK: - Published Properties
    // These automatically update the UI when data changes
    @Published var savedLocations: [SimpleSavedLocation] = []
    @Published var savedRoutes: [SimpleRoute] = []
    @Published var detectionRecords: [SimpleDetectionRecord] = []
    @Published var userAccount: SimpleUserAccount
    
    // MARK: - Initialization
    private init() {
        // Initialize with default user account
        self.userAccount = SimpleUserAccount(
            name: "SmartCane User",
            email: "",
            phone: ""
        )
        
        // Load all saved data
        loadAllData()
    }
    
    // MARK: - Data Loading Methods
    
    private func loadAllData() {
        loadSavedLocations()
        loadSavedRoutes()
        loadDetectionRecords()
        loadUserAccount()
    }
    
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let locations = try? JSONDecoder().decode([SimpleSavedLocation].self, from: data) {
            savedLocations = locations
        }
    }
    
    private func loadSavedRoutes() {
        if let data = UserDefaults.standard.data(forKey: "savedRoutes"),
           let routes = try? JSONDecoder().decode([SimpleRoute].self, from: data) {
            savedRoutes = routes
        }
    }
    
    private func loadDetectionRecords() {
        if let data = UserDefaults.standard.data(forKey: "detectionRecords"),
           let records = try? JSONDecoder().decode([SimpleDetectionRecord].self, from: data) {
            detectionRecords = records
        }
    }
    
    private func loadUserAccount() {
        if let data = UserDefaults.standard.data(forKey: "userAccount"),
           let account = try? JSONDecoder().decode(SimpleUserAccount.self, from: data) {
            userAccount = account
        }
    }
    
    // MARK: - Data Saving Methods
    
    func saveAllData() {
        saveSavedLocations()
        saveSavedRoutes()
        saveDetectionRecords()
        saveUserAccount()
    }
    
    private func saveSavedLocations() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "savedLocations")
        }
    }
    
    private func saveSavedRoutes() {
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: "savedRoutes")
        }
    }
    
    private func saveDetectionRecords() {
        if let data = try? JSONEncoder().encode(detectionRecords) {
            UserDefaults.standard.set(data, forKey: "detectionRecords")
        }
    }
    
    private func saveUserAccount() {
        if let data = try? JSONEncoder().encode(userAccount) {
            UserDefaults.standard.set(data, forKey: "userAccount")
        }
    }
    
    // MARK: - Public Methods for Adding Data
    
    func addSavedLocation(_ location: SimpleSavedLocation) {
        savedLocations.append(location)
        saveSavedLocations()
    }
    
    func addSavedRoute(_ route: SimpleRoute) {
        savedRoutes.append(route)
        saveSavedRoutes()
    }
    
    func addDetectionRecord(_ record: SimpleDetectionRecord) {
        detectionRecords.append(record)
        saveDetectionRecords()
    }
    
    func updateUserAccount(name: String, email: String, phone: String) {
        userAccount.name = name
        userAccount.email = email
        userAccount.phone = phone
        saveUserAccount()
    }
    
    // MARK: - Public Methods for Deleting Data
    
    func deleteSavedLocation(_ location: SimpleSavedLocation) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations.remove(at: index)
            saveSavedLocations()
        }
    }
    
    func deleteSavedRoute(_ route: SimpleRoute) {
        if let index = savedRoutes.firstIndex(where: { $0.id == route.id }) {
            savedRoutes.remove(at: index)
            saveSavedRoutes()
        }
    }
    
    func deleteDetectionRecord(_ record: SimpleDetectionRecord) {
        if let index = detectionRecords.firstIndex(where: { $0.id == record.id }) {
            detectionRecords.remove(at: index)
            saveDetectionRecords()
        }
    }
    
    // MARK: - Search and Filter Methods
    
    func searchSavedLocations(query: String) -> [SimpleSavedLocation] {
        if query.isEmpty {
            return savedLocations
        }
        return savedLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(query) ||
            location.address.localizedCaseInsensitiveContains(query) ||
            location.notes.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchSavedRoutes(query: String) -> [SimpleRoute] {
        if query.isEmpty {
            return savedRoutes
        }
        return savedRoutes.filter { route in
            route.name.localizedCaseInsensitiveContains(query) ||
            route.notes.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getLocationsByCategory(_ category: String) -> [SimpleSavedLocation] {
        if category == "All" {
            return savedLocations
        }
        return savedLocations.filter { $0.category == category }
    }
    
    func getRoutesByType(_ type: String) -> [SimpleRoute] {
        if type == "All" {
            return savedRoutes
        }
        return savedRoutes.filter { $0.routeType == type }
    }
}

// MARK: - Simple Data Models

struct SimpleSavedLocation: Identifiable, Codable {
    let id = UUID()
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: String
    var notes: String
    var dateAdded: Date
    
    // MARK: - Category Enum
    enum LocationCategory: String, CaseIterable {
        case home = "Home"
        case work = "Work"
        case shopping = "Shopping"
        case recreation = "Recreation"
        case medical = "Medical"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "building.2.fill"
            case .shopping: return "cart.fill"
            case .recreation: return "leaf.fill"
            case .medical: return "cross.fill"
            case .other: return "mappin.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .home: return .blue
            case .work: return .green
            case .shopping: return .orange
            case .recreation: return .purple
            case .medical: return .red
            case .other: return .gray
            }
        }
    }
}

struct SimpleRoute: Identifiable, Codable {
    let id = UUID()
    var name: String
    var origin: SimpleLocation
    var destination: SimpleLocation
    var routeType: String
    var preferredTransportMode: String
    var notes: String
    var dateCreated: Date
}

struct SimpleLocation: Codable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
}

struct SimpleDetectionRecord: Identifiable, Codable {
    let id = UUID()
    var objectType: String
    var confidence: Double
    var dateCreated: Date
}

struct SimpleUserAccount: Codable {
    var name: String
    var email: String
    var phone: String
}
