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
    
