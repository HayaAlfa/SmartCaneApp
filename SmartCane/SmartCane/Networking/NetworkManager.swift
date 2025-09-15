//
//  NetworkManager.swift
//  SmartCane
//
//  Created by Assistant on 12/19/24.
//

import Foundation

// MARK: - Simple Network Manager
// Basic networking with dummy JSON data
class NetworkManager {
    
    // MARK: - Singleton
    static let shared = NetworkManager()
    
    // MARK: - Simple Data Models
    struct ObstacleData: Codable, Identifiable {
        let id: String
        let name: String
        let type: String
        let confidence: Double
    }
    
    struct UserData: Codable, Identifiable {
        let id: String
        let name: String
        let email: String
    }
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Network Methods
    
    // Fetch dummy obstacles
    func fetchObstacles(completion: @escaping (Result<[ObstacleData], Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let obstacles = [
                ObstacleData(id: "1", name: "Park Bench", type: "Furniture", confidence: 0.95),
                ObstacleData(id: "2", name: "Traffic Cone", type: "Traffic", confidence: 0.88),
                ObstacleData(id: "3", name: "Tree", type: "Natural", confidence: 0.92)
            ]
            
            DispatchQueue.main.async {
                completion(.success(obstacles))
            }
        }
    }
    
    // Fetch dummy user data
    func fetchUserData(userId: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let user = UserData(id: "123", name: "John Doe", email: "john@example.com")
            
            DispatchQueue.main.async {
                completion(.success(user))
            }
        }
    }
    
    // Post obstacle detection (dummy)
    func postObstacleDetection(obstacle: ObstacleData, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
            DispatchQueue.main.async {
                completion(.success("Obstacle logged successfully"))
            }
        }
    }
}
