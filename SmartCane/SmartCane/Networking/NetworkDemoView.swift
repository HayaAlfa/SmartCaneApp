//
//  NetworkDemoView.swift
//  SmartCane
//
//  Created by Assistant on 12/19/24.
//

import SwiftUI

// MARK: - Simple Network Demo View
struct NetworkDemoView: View {
    
    @State private var obstacles: [NetworkManager.ObstacleData] = []
    @State private var userData: NetworkManager.UserData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                buttonSection
                resultsSection
                errorSection
                Spacer()
            }
            .navigationTitle("Network Demo")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack {
            Image(systemName: "network")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Network Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Test networking with dummy JSON")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Button Section
    private var buttonSection: some View {
        VStack(spacing: 16) {
            Button("Fetch Obstacles") {
                fetchObstacles()
            }
            .buttonStyle(DemoButtonStyle(color: .blue))
            .disabled(isLoading)
            
            Button("Fetch User Data") {
                fetchUserData()
            }
            .buttonStyle(DemoButtonStyle(color: .green))
            .disabled(isLoading)
            
            Button("Test POST") {
                testPostRequest()
            }
            .buttonStyle(DemoButtonStyle(color: .orange))
            .disabled(isLoading)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack {
            if !obstacles.isEmpty {
                obstaclesView
            }
            
            if let user = userData {
                userDataView(user: user)
            }
        }
    }
    
    // MARK: - Obstacles View
    private var obstaclesView: some View {
        VStack(alignment: .leading) {
            Text("Obstacles (\(obstacles.count))")
                .font(.headline)
            
            ForEach(obstacles) { obstacle in
                HStack {
                    Text(obstacle.name)
                    Spacer()
                    Text("\(Int(obstacle.confidence * 100))%")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - User Data View
    private func userDataView(user: NetworkManager.UserData) -> some View {
        VStack(alignment: .leading) {
            Text("User Data")
                .font(.headline)
            
            Text("Name: \(user.name)")
            Text("Email: \(user.email)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Error Section
    private var errorSection: some View {
        Group {
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    // MARK: - Network Methods
    
    private func fetchObstacles() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchObstacles { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let obstacles):
                    self.obstacles = obstacles
                    self.errorMessage = nil
                    print("✅ Fetched \(obstacles.count) obstacles")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed: \(error)")
                }
            }
        }
    }
    
    private func fetchUserData() {
        isLoading = true
        errorMessage = nil
        
        NetworkManager.shared.fetchUserData(userId: "123") { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    self.userData = user
                    self.errorMessage = nil
                    print("✅ Fetched user: \(user.name)")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed: \(error)")
                }
            }
        }
    }
    
    private func testPostRequest() {
        isLoading = true
        errorMessage = nil
        
        let obstacle = NetworkManager.ObstacleData(
            id: "test",
            name: "Test Obstacle",
            type: "Test",
            confidence: 0.95
        )
        
        NetworkManager.shared.postObstacleDetection(obstacle: obstacle) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.errorMessage = nil
                    print("✅ Posted: \(response)")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Button Style
struct DemoButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    NetworkDemoView()
}
