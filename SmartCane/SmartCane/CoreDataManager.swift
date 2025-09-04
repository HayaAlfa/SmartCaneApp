/*
import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Manager
// This class manages all Core Data operations for the SmartCane app
class CoreDataManager: ObservableObject {
    
    // MARK: - Singleton Pattern
    // Shared instance that can be used across the app
    static let shared = CoreDataManager()
    
    // MARK: - Published Properties
    // These properties automatically update the UI when they change
    @Published var savedLocations: [SavedLocation] = []
    @Published var savedRoutes: [SavedRoute] = []
    @Published var userAccount: UserAccount?
    @Published var detectionRecords: [DetectionRecord] = []
    
    // MARK: - Core Data Stack
    let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    private init() {
        // Initialize Core Data container
        container = NSPersistentContainer(name: "SmartCane")
        
        // Load the persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        // Get the main context
        context = container.viewContext
        
        // Set up automatic saving
        context.automaticallyMergesChangesFromParent = true
        
        // Load initial data
        loadAllData()
    }
    
    // MARK: - Data Loading
    
    // Load all data from Core Data
    private func loadAllData() {
        loadSavedLocations()
        loadSavedRoutes()
        loadUserAccount()
        loadDetectionRecords()
    }
    
    // MARK: - Saved Locations Management
    
    // Load saved locations from Core Data
    private func loadSavedLocations() {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.dateAdded, ascending: false)]
        
        do {
            savedLocations = try context.fetch(request)
            print("📍 Loaded \(savedLocations.count) saved locations")
        } catch {
            print("❌ Failed to load saved locations: \(error)")
        }
    }
    
    // Add a new saved location
    func addSavedLocation(name: String, address: String, latitude: Double, longitude: Double, category: String, notes: String) {
        let newLocation = SavedLocation(context: context)
        newLocation.id = UUID()
        newLocation.name = name
        newLocation.address = address
        newLocation.latitude = latitude
        newLocation.longitude = longitude
        newLocation.category = category
        newLocation.notes = notes
        newLocation.dateAdded = Date()
        
        saveContext()
        loadSavedLocations()
        
        print("✅ Added new saved location: \(name)")
    }
    
    // Update an existing saved location
    func updateSavedLocation(_ location: SavedLocation, name: String, address: String, category: String, notes: String) {
        location.name = name
        location.address = address
        location.category = category
        location.notes = notes
        
        saveContext()
        loadSavedLocations()
        
        print("✅ Updated saved location: \(name)")
    }
    
    // Delete a saved location
    func deleteSavedLocation(_ location: SavedLocation) {
        context.delete(location)
        saveContext()
        loadSavedLocations()
        
        print("🗑️ Deleted saved location: \(location.name ?? "Unknown")")
    }
    
    // MARK: - Saved Routes Management
    
    // Load saved routes from Core Data
    private func loadSavedRoutes() {
        let request: NSFetchRequest<SavedRoute> = SavedRoute.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedRoute.dateCreated, ascending: false)]
        
        do {
            savedRoutes = try context.fetch(request)
            print("🛣️ Loaded \(savedRoutes.count) saved routes")
        } catch {
            print("❌ Failed to load saved routes: \(error)")
        }
    }
    
    // Add a new saved route
    func addSavedRoute(name: String, origin: SavedLocation, destination: SavedLocation, routeType: String, preferredTransportMode: String, notes: String, waypoints: [SavedLocation] = []) {
        let newRoute = SavedRoute(context: context)
        newRoute.id = UUID()
        newRoute.name = name
        newRoute.origin = origin
        newRoute.destination = origin
        newRoute.routeType = routeType
        newRoute.preferredTransportMode = preferredTransportMode
        newRoute.notes = notes
        newRoute.dateCreated = Date()
        
        // Add waypoints if any
        for waypoint in waypoints {
            newRoute.addToWaypoints(waypoint)
        }
        
        saveContext()
        loadSavedRoutes()
        
        print("✅ Added new saved route: \(name)")
    }
    
    // Update an existing saved route
    func updateSavedRoute(_ route: SavedRoute, name: String, routeType: String, preferredTransportMode: String, notes: String, waypoints: [SavedLocation] = []) {
        route.name = name
        route.routeType = routeType
        route.preferredTransportMode = preferredTransportMode
        route.notes = notes
        
        // Clear existing waypoints and add new ones
        route.waypoints?.removeAllObjects()
        for waypoint in waypoints {
            route.addToWaypoints(waypoint)
        }
        
        saveContext()
        loadSavedRoutes()
        
        print("✅ Updated saved route: \(name)")
    }
    
    // Delete a saved route
    func deleteSavedRoute(_ route: SavedRoute) {
        context.delete(route)
        saveContext()
        loadSavedRoutes()
        
        print("🗑️ Deleted saved route: \(route.name ?? "Unknown")")
    }
    
    // MARK: - User Account Management
    
    // Load user account from Core Data
    private func loadUserAccount() {
        let request: NSFetchRequest<UserAccount> = UserAccount.fetchRequest()
        
        do {
            let accounts = try context.fetch(request)
            if let account = accounts.first {
                userAccount = account
                print("👤 Loaded user account: \(account.name ?? "Unknown")")
            } else {
                // Create default user account if none exists
                createDefaultUserAccount()
            }
        } catch {
            print("❌ Failed to load user account: \(error)")
        }
    }
    
    // Create default user account
    private func createDefaultUserAccount() {
        let newAccount = UserAccount(context: context)
        newAccount.id = UUID()
        newAccount.name = "User"
        newAccount.email = ""
        newAccount.phone = ""
        
        saveContext()
        userAccount = newAccount
        
        print("👤 Created default user account")
    }
    
    // Update user account
    func updateUserAccount(name: String, email: String, phone: String) {
        guard let account = userAccount else { return }
        
        account.name = name
        account.email = email
        account.phone = phone
        
        saveContext()
        
        print("✅ Updated user account: \(name)")
    }
    
    // MARK: - Detection Records Management
    
    // Load detection records from Core Data
    private func loadDetectionRecords() {
        let request: NSFetchRequest<DetectionRecord> = DetectionRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DetectionRecord.dateCreated, ascending: false)]
        
        do {
            detectionRecords = try context.fetch(request)
            print("🔍 Loaded \(detectionRecords.count) detection records")
        } catch {
            print("❌ Failed to load detection records: \(error)")
        }
    }
    
    // Add a new detection record
    func addDetectionRecord(objectType: String, confidence: Double) {
        let newRecord = DetectionRecord(context: context)
        newRecord.id = UUID()
        newRecord.objectType = objectType
        newRecord.confidence = confidence
        newRecord.dateCreated = Date()
        
        saveContext()
        loadDetectionRecords()
        
        print("✅ Added detection record: \(objectType)")
    }
    
    // Delete a detection record
    func deleteDetectionRecord(_ record: DetectionRecord) {
        context.delete(record)
        saveContext()
        loadDetectionRecords()
        
        print("🗑️ Deleted detection record: \(record.objectType ?? "Unknown")")
    }
    
    // MARK: - Search and Filter Functions
    
    // Search saved locations by name, address, or notes
    func searchSavedLocations(query: String) -> [SavedLocation] {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        
        if !query.isEmpty {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR address CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query, query)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.dateAdded, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to search saved locations: \(error)")
            return []
        }
    }
    
    // Filter saved locations by category
    func filterSavedLocations(by category: String?) -> [SavedLocation] {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        
        if let category = category {
            request.predicate = NSPredicate(format: "category == %@", category)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedLocation.dateAdded, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to filter saved locations: \(error)")
            return []
        }
    }
    
    // Search saved routes by name or notes
    func searchSavedRoutes(query: String) -> [SavedRoute] {
        let request: NSFetchRequest<SavedRoute> = SavedRoute.fetchRequest()
        
        if !query.isEmpty {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedRoute.dateCreated, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to search saved routes: \(error)")
            return []
        }
    }
    
    // MARK: - Utility Functions
    
    // Save the Core Data context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("💾 Core Data context saved successfully")
            } catch {
                print("❌ Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // Get location by ID
    func getLocation(by id: UUID) -> SavedLocation? {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to get location by ID: \(error)")
            return nil
        }
    }
    
    // Get route by ID
    func getRoute(by id: UUID) -> SavedRoute? {
        let request: NSFetchRequest<SavedRoute> = SavedRoute.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to get route by ID: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Export/Import
    
    // Export all data as JSON (for backup purposes)
    func exportAllData() -> Data? {
        let exportData: [String: Any] = [
            "savedLocations": savedLocations.map { location in
                [
                    "id": location.id?.uuidString ?? "",
                    "name": location.name ?? "",
                    "address": location.address ?? "",
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "category": location.category ?? "",
                    "notes": location.notes ?? "",
                    "dateAdded": location.dateAdded?.timeIntervalSince1970 ?? 0
                ]
            },
            "savedRoutes": savedRoutes.map { route in
                [
                    "id": route.id?.uuidString ?? "",
                    "name": route.name ?? "",
                    "routeType": route.routeType ?? "",
                    "preferredTransportMode": route.preferredTransportMode ?? "",
                    "notes": route.notes ?? "",
                    "originId": route.origin?.id?.uuidString ?? "",
                    "destinationId": route.destination?.id?.uuidString ?? "",
                    "dateCreated": route.dateCreated?.timeIntervalSince1970 ?? 0
                ]
            },
            "userAccount": [
                "id": userAccount?.id?.uuidString ?? "",
                "UserAccount",
                "name": userAccount?.name ?? "",
                "email": userAccount?.email ?? "",
                "phone": userAccount?.phone ?? ""
            ],
            "detectionRecords": detectionRecords.map { record in
                [
                    "id": record.id?.uuidString ?? "",
                    "objectType": record.objectType ?? "",
                    "confidence": record.confidence,
                    "dateCreated": record.dateCreated?.timeIntervalSince1970 ?? 0
                ]
            }
        ]
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("❌ Failed to export data: \(error)")
            return nil
        }
    }
}
*/

// TEMPORARY: Simple data structures without Core Data
import Foundation
import SwiftUI

// Simple data models for temporary use
struct TempSavedLocation: Identifiable {
    let id = UUID()
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: String
    var notes: String
    var dateAdded: Date
}

struct TempSavedRoute: Identifiable {
    let id = UUID()
    var name: String
    var origin: TempSavedLocation
    var destination: TempSavedLocation
    var routeType: String
    var preferredTransportMode: String
    var notes: String
    var dateCreated: Date
}

struct TempUserAccount {
    var name: String
    var email: String
    var phone: String
}

struct TempDetectionRecord: Identifiable {
    let id = UUID()
    var objectType: String
    var confidence: Double
    var dateCreated: Date
}

// Simple data manager using UserDefaults temporarily
class TempDataManager: ObservableObject {
    static let shared = TempDataManager()
    
    @Published var savedLocations: [TempSavedLocation] = []
    @Published var savedRoutes: [TempSavedRoute] = []
    @Published var userAccount = TempUserAccount(name: "User", email: "", phone: "")
    @Published var detectionRecords: [TempDetectionRecord] = []
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        // Load from UserDefaults temporarily
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let locations = try? JSONDecoder().decode([TempSavedLocation].self, from: data) {
            savedLocations = locations
        }
        
        if let data = UserDefaults.standard.data(forKey: "userAccount"),
           let account = try? JSONDecoder().decode(TempUserAccount.self, from: data) {
            userAccount = account
        }
    }
    
    func saveData() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(data, forKey: "savedLocations")
        }
        
        if let data = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(data, forKey: "savedRoutes")
        }
        
        if let data = try? JSONEncoder().encode(userAccount) {
            UserDefaults.standard.set(data, forKey: "userAccount")
        }
        
        if let data = try? JSONEncoder().encode(detectionRecords) {
            UserDefaults.standard.set(data, forKey: "detectionRecords")
        }
    }
}
