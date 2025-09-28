//
//  ExportLogs.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/14/25.
//
// ExportLogs.swift
import SwiftUI

struct ExportLogs: View {
    let logs: [ObstacleLog]
    
    var body: some View {
        VStack {
            Text("Export Logs")
                .font(.title2)
                .padding()
            
            if let fileURL = saveCSVFile(csvText: exportLogsToCSV(logs)) {
                ShareLink(item: fileURL) {
                    Label("Export Logs (CSV)", systemImage: "square.and.arrow.up")
                }
            } else {
                Text("Failed to generate CSV file")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .navigationTitle("Export Logs")
    }
}


func exportLogsToCSV(_ logs: [ObstacleLog]) -> String {
    var csv = "Obstacle Type,Time,Location\n"
    for log in logs {
        csv += "\(log.obstacleType),\(log.timestamp ?? Date()),\(log.deviceId)\n"
    }
    return csv
}

func saveCSVFile(csvText: String) -> URL? {
    let filename = "ObstacleLogs.csv"
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(filename)
    
    do {
        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    } catch {
        print("Error saving CSV file:", error)
        return nil
    }
}

