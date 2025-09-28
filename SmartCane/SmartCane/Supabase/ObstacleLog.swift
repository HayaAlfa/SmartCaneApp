////
//// ObstacleLog.swift
//// SmartCane
////
//// Created by Haya Alfakieh on 9/17/25.
////
//
//import SwiftUI
//import Foundation
//
//// MARK: - Updated ObstacleLog Model for Supabase
//struct ObstacleLog: Identifiable, Codable {
//    let id: UUID
//    let time: String           // Keep your existing time format
//    let type: String           // Keep your existing type names
//    let location: String       // Keep your existing location format
//    
//    // New Supabase fields (optional to maintain backward compatibility)
//    let deviceId: String?
//    let distanceCm: Int?
//    let confidenceScore: Double?
//    let sensorType: String?
//    let latitude: Double?
//    let longitude: Double?
//    let timestamp: Date?
//    let userVerified: Bool?
//    let severityLevel: Int?
//    let createdAt: Date?
//    
//    // Supabase column mapping
//    enum CodingKeys: String, CodingKey {
//        case id
//        case time = "time_display"  // Your display time format
//        case type = "obstacle_type"
//        case location = "location_display"  // Your display location format
//        case deviceId = "device_id"
//        case distanceCm = "distance_cm"
//        case confidenceScore = "confidence_score"
//        case sensorType = "sensor_type"
//        case latitude
//        case longitude
//        case timestamp
//        case userVerified = "user_verified"
//        case severityLevel = "severity_level"
//        case createdAt = "created_at"
//    }
//    
//    // Initialize for your existing UI (backward compatibility)
//    init(time: String, type: String, location: String) {
//        self.id = UUID()
//        self.time = time
//        self.type = type
//        self.location = location
//        // Set optional fields to nil for existing data
//        self.deviceId = nil
//        self.distanceCm = nil
//        self.confidenceScore = nil
//        self.sensorType = nil
//        self.latitude = nil
//        self.longitude = nil
//        self.timestamp = nil
//        self.userVerified = nil
//        self.severityLevel = nil
//        self.createdAt = nil
//    }
//    
//    // Initialize from ESP32 sensor data
//    init(deviceId: String, type: String, distanceCm: Int, confidenceScore: Double,
//         sensorType: String, severityLevel: Int, latitude: Double? = nil, longitude: Double? = nil) {
//        self.id = UUID()
//        self.deviceId = deviceId
//        self.type = type
//        self.distanceCm = distanceCm
//        self.confidenceScore = confidenceScore
//        self.sensorType = sensorType
//        self.severityLevel = severityLevel
//        self.latitude = latitude
//        self.longitude = longitude
//        self.timestamp = Date()
//        self.userVerified = nil
//        self.createdAt = nil
//        
//        // Generate display formats for your existing UI
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        self.time = formatter.string(from: Date())
//        self.location = "GPS Location" // Or format from lat/long if available
//    }
//}
//
//// Keep your existing sample data for testing
//let sampleLogs = [
//    ObstacleLog(time: "10:32 AM", type: "Wall", location: "Living Room"),
//    ObstacleLog(time: "10:35 AM", type: "Step", location: "Staircase"),
//    ObstacleLog(time: "10:40 AM", type: "Person", location: "Kitchen")
//]
//
//// MARK: - Updated CSV Export Helpers
//func exportLogsToCSV(_ logs: [ObstacleLog]) -> String {
//    var csvString = "Time,Type,Location,Distance(cm),Confidence,Sensor,Severity\n"
//    for log in logs {
//        let distance = log.distanceCm?.description ?? ""
//        let confidence = log.confidenceScore?.description ?? ""
//        let sensor = log.sensorType ?? ""
//        let severity = log.severityLevel?.description ?? ""
//        csvString += "\(log.time),\(log.type),\(log.location),\(distance),\(confidence),\(sensor),\(severity)\n"
//    }
//    return csvString
//}
//
//func saveCSVFile(csvText: String) -> URL? {
//    let fileName = "obstacleLogs_\(Date().timeIntervalSince1970).csv"
//    let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
//    
//    do {
//        try csvText.write(to: path, atomically: true, encoding: .utf8)
//        return path
//    } catch {
//        print("Error saving CSV: \(error)")
//        return nil
//    }
//}
//
//// MARK: - Enhanced Logs List Screen
//struct ObstacleLogsView: View {
//    @StateObject private var dataService = SmartCaneDataService()
//    @State private var logs: [ObstacleLog] = sampleLogs  // Start with sample data
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//    @State private var showingExportSheet = false
//    
//    let deviceId = "SmartCane_001"
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if isLoading {
//                    ProgressView("Loading obstacle logs...")
//                        .padding()
//                }
//                
//                List(logs) { log in
//                    ObstacleLogRowView(log: log, dataService: dataService)
//                }
//                .refreshable {
//                    await loadLogsFromSupabase()
//                }
//            }
//            .navigationTitle("Obstacle Logs")
//            .toolbar {
//                ToolbarItemGroup(placement: .navigationBarTrailing) {
//                    Button("Export") {
//                        showingExportSheet = true
//                    }
//                    
//                    Button("Refresh") {
//                        Task {
//                            await loadLogsFromSupabase()
//                        }
//                    }
//                }
//            }
//            .onAppear {
//                Task {
//                    await loadLogsFromSupabase()
//                }
//            }
//            .alert("Error", isPresented: .constant(errorMessage != nil)) {
//                Button("OK") { errorMessage = nil }
//            } message: {
//                Text(errorMessage ?? "")
//            }
//            .sheet(isPresented: $showingExportSheet) {
//                ExportLogsView(logs: logs)
//            }
//        }
//    }
//    
//    @MainActor
//    private func loadLogsFromSupabase() async {
//        isLoading = true
//        do {
//            let supabaseLogs = try await dataService.getObstacleHistory(deviceId: deviceId)
//            logs = supabaseLogs.isEmpty ? sampleLogs : supabaseLogs
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//            // Keep sample logs if Supabase fails
//        }
//    }
//}
//
//// MARK: - Enhanced Log Row View
//struct ObstacleLogRowView: View {
//    let log: ObstacleLog
//    let dataService: SmartCaneDataService
//    @State private var isVerifying = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            HStack {
//                Text("[\(log.time)] \(log.type) detected")
//                    .font(.headline)
//                
//                Spacer()
//                
//                // Show verification status if available
//                if let verified = log.userVerified {
//                    Image(systemName: verified ? "checkmark.circle.fill" : "xmark.circle.fill")
//                        .foregroundColor(verified ? .green : .red)
//                }
//            }
//            
//            Text(log.location)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//            
//            // Show additional sensor data if available
//            if let distance = log.distanceCm, let confidence = log.confidenceScore {
//                HStack {
//                    Text("Distance: \(distance)cm")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text("Confidence: \(Int(confidence * 100))%")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            // Verification buttons for unverified obstacles
//            if log.userVerified == nil && log.deviceId != nil {
//                HStack {
//                    Button("✅ Correct") {
//                        verifyObstacle(correct: true)
//                    }
//                    .buttonStyle(.bordered)
//                    .controlSize(.small)
//                    
//                    Button("❌ False Alert") {
//                        verifyObstacle(correct: false)
//                    }
//                    .buttonStyle(.bordered)
//                    .controlSize(.small)
//                    
//                    Spacer()
//                }
//                .padding(.top, 4)
//                .disabled(isVerifying)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//    
//    private func verifyObstacle(correct: Bool) {
//        isVerifying = true
//        Task {
//            do {
//                try await dataService.verifyObstacle(id: log.id, verified: correct)
//                await MainActor.run {
//                    isVerifying = false
//                }
//            } catch {
//                print("Error verifying obstacle: \(error)")
//                await MainActor.run {
//                    isVerifying = false
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Export Logs View
//struct ExportLogsView: View {
//    let logs: [ObstacleLog]
//    @Environment(\.dismiss) private var dismiss
//    @State private var exportURL: URL?
//    @State private var showingShareSheet = false
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                Text("Export \(logs.count) obstacle logs")
//                    .font(.headline)
//                
//                Button("Export as CSV") {
//                    let csvText = exportLogsToCSV(logs)
//                    exportURL = saveCSVFile(csvText: csvText)
//                    if exportURL != nil {
//                        showingShareSheet = true
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//                
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Export Logs")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//            }
//            .sheet(isPresented: $showingShareSheet) {
//                if let url = exportURL {
//                    ActivityViewController(activityItems: [url])
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Activity View Controller for Sharing
//struct ActivityViewController: UIViewControllerRepresentable {
//    let activityItems: [Any]
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}
