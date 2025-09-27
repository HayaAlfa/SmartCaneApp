import SwiftUI



struct WarningTestView: View {
    @State private var signalText: String = ""
    @State private var showingWarning = false
    @State private var currentWarning = ""
    private let sensorProcessor = SensorSignal()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Waring Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Test ESP32 Bluetooth signal parsing")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                
                //using Waring section
                VStack(spacing: 15) {
                    Text("Valid ESP32 Signal Input")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("F:30")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                            Text("Front obstacle 30cm")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("L:20")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                            Text("Left obstacle 20cm")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("R:15")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                            Text("Right obstacle 15cm")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("STOP")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                            Text("Stop immediately")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("CLEAR")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                            Text("Path is clear")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .padding(.horizontal)
                }
                
                // Signal input section
                VStack(spacing: 15) {
                    Text("ESP32 Signal Input")
                        .font(.headline)
                    
                    TextField("Enter signal text from ESP32...", text: $signalText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .padding(.horizontal)
                    
                    Button("Produce warning") {
                        parseSignal()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(signalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                }
                
                //Warning output section
                if showingWarning {
                    VStack(spacing: 15) {
                        Text("Warning Output")
                            .font(.headline)
                        
                        Text(currentWarning)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
            
                
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseSignal() {
        let signal = signalText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use SensorSignalProcessor to process the input
        let result = sensorProcessor.receiveSignal(signal)
        
        // Check if the result indicates invalid input
        if result == "Unknown signal received." || result.isEmpty {
            currentWarning = "Invalid input, do again"
        } else {
            currentWarning = result
        }
        
        showingWarning = true
        
        // Clear the input field after processing
        signalText = ""
    }
}

// MARK: - Preview
#Preview {
    WarningTestView()
}
