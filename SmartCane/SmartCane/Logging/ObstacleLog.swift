//
//  ObstacleLog.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/17/25.
//

import SwiftUI

struct ObstacleLog: Identifiable {
    let id = UUID()
    let time: String
    let type: String
    let location: String
}

let sampleLogs = [
    ObstacleLog(time: "10:32 AM", type: "Wall", location: "Living Room"),
    ObstacleLog(time: "10:35 AM", type: "Step", location: "Staircase"),
    ObstacleLog(time: "10:40 AM", type: "Person", location: "Kitchen")
]

// MARK: - CSV Export Helpers
func exportLogsToCSV(_ logs: [ObstacleLog]) -> String {
    var csvString = "Time,Type,Location\n"
    for log in logs {
        csvString += "\(log.time),\(log.type),\(log.location)\n"
    }
    return csvString
}

func saveCSVFile(csvText: String) -> URL? {
    let fileName = "obstacleLogs.csv"
    let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    
    do {
        try csvText.write(to: path, atomically: true, encoding: .utf8)
        return path
    } catch {
        print("Error saving CSV: \(error)")
        return nil
    }
}

// MARK: - Logs List Screen
struct ObstacleLogsView: View {
    let logs: [ObstacleLog] = sampleLogs
    
    var body: some View {
        List(logs) { log in
            VStack(alignment: .leading, spacing: 4) {
                Text("[\(log.time)] \(log.type) detected")
                    .font(.headline)
                Text(log.location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Obstacle Logs")
    }
}
