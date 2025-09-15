import Foundation
import SwiftUI

// MARK: - Model
struct SimpleSavedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: String
    var notes: String
    var dateAdded: Date

    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double, category: String, notes: String, dateAdded: Date) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.notes = notes
        self.dateAdded = dateAdded
    }

    // Categorization helper for UI
    enum LocationCategory: String, CaseIterable, Codable {
        case home = "Home"
        case work = "Work"
        case school = "School"
        case favorite = "Favorite"
        case other = "Other"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "briefcase.fill"
            case .school: return "graduationcap.fill"
            case .favorite: return "star.fill"
            case .other: return "mappin"
            }
        }

        var color: Color {
            switch self {
            case .home: return .blue
            case .work: return .purple
            case .school: return .orange
            case .favorite: return .yellow
            case .other: return .gray
            }
        }
    }
}

// MARK: - Data Manager (in-memory)
final class SimpleDataManager: ObservableObject {
    static let shared = SimpleDataManager()

    @Published var savedLocations: [SimpleSavedLocation] = []

    private init() {}

    func addSavedLocation(_ location: SimpleSavedLocation) {
        savedLocations.append(location)
    }

    func deleteSavedLocation(_ location: SimpleSavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
    }
}

