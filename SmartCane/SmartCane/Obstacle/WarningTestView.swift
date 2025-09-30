import SwiftUI
import CoreML
import Vision

struct WarningTestView: View {
    @State private var signalText: String = ""
    @State private var showingWarning = false
    @State private var currentWarning = ""
    @State private var isProcessing = false
    @State private var currentObstacle: Obstacle?
    @State private var capturedImage: UIImage?
    @State private var currentSignal: String = ""
    private let sensorProcessor = SensorSignal()
    private let autoCamera = AutoCameraCapture.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                
                //using Warning section
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
                    
                    TextField("Enter signal text from ESP32...", text: $signalText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .onSubmit {
                            // Process signal when user presses return
                            // TRIGGER POINT 1: Return key press
                            parseSignal()
                        }
                    
                    Button("Produce warning") {
                        // TRIGGER POINT 2: Button click
                        parseSignal()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(signalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    
                }
                
                // Processing indicator
                if isProcessing {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing...")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding()
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
                        
                        // Show obstacle details if available
                        if let obstacle = currentObstacle {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detected Obstacle:")
                                    .font(.headline)
                                Text("Type: \(obstacle.type)")
                                Text("Distance: \(String(format: "%.1f", obstacle.distance)) cm")
                                Text("Detected: \(obstacle.detectedAt.formatted())")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                }
                }
                .padding(.bottom, 50) // Extra padding at bottom for keyboard
            }
            .onAppear {
                autoCamera.startSession()
            }
            .onDisappear {
                autoCamera.stopSession()
            }
            .onChange(of: autoCamera.capturedImage) { _, newImage in
                print("📸 onChange triggered, newImage: \(newImage != nil ? "exists" : "nil")")
                if let image = newImage {
                    capturedImage = image
                    processCapturedImage()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func parseSignal() {
        let signal = signalText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use SensorSignalProcessor to process the input
        let result = sensorProcessor.receiveSignal(signal)
        
        // Check if the result indicates invalid input
        if result == "Unknown signal received." || result.isEmpty {
            currentWarning = "Invalid input, do again"
            showingWarning = true
            signalText = ""
            return
        }
        
        // Valid signal received - trigger auto camera capture
        print("📸 Valid signal received: \(signal) - triggering auto camera capture")
        currentSignal = signal // Store the signal for later processing
        isProcessing = true
        showingWarning = false
        currentObstacle = nil
        
        // Auto-capture photo
        print("📸 Calling autoCamera.capturePhoto()...")
        autoCamera.capturePhoto()
        
        // Clear the input field
        signalText = ""
        
        // Wait for photo capture and then process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let image = self.autoCamera.capturedImage {
                print("📸 Photo captured, processing...")
                self.capturedImage = image
                self.processCapturedImage()
            } else {
                print("❌ No image captured after 2 seconds")
                self.isProcessing = false
                self.currentWarning = "Failed to capture image"
                self.showingWarning = true
            }
        }
    }
    
    private func processCapturedImage() {
        guard let image = capturedImage else { return }
        
        print("🔍 Processing captured image...")
        
        // Extract distance from the stored signal
        let distance = extractDistanceFromSignal(currentSignal)
        
        // Use existing ObstacleClassifierManager
        ObstacleClassifierManager.shared.classify(image: image) { result, confidence in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                let objectType = result.isEmpty ? "Unknown Object" : result
                
                // Create obstacle with sensor distance + vision type
                let obstacle = Obstacle(
                    type: objectType,
                    latitude: 0.0, // Will be updated with real GPS later
                    longitude: 0.0, // Will be updated with real GPS later
                    detectedAt: Date(),
                    distance: distance
                )
                
                self.currentObstacle = obstacle
                
                // Create final warning message using SensorSignal formulas
                let baseWarning = self.sensorProcessor.receiveSignal(self.currentSignal)
                let finalWarning = self.integrateObstacleType(baseWarning: baseWarning, obstacleType: objectType)
                self.currentWarning = finalWarning
                self.showingWarning = true
                
                print("✅ Obstacle created: \(objectType) at \(distance) cm")
            }
        }
    }
    
    private func extractDistanceFromSignal(_ signal: String) -> Float {
        if signal.hasPrefix("F:") || signal.hasPrefix("L:") || signal.hasPrefix("R:") {
            let parts = signal.split(separator: ":")
            if parts.count >= 2, let distance = Int(parts[1]) {
                return Float(distance)
            }
        }
        return 30.0 // Default distance if not found
    }
    
    private func integrateObstacleType(baseWarning: String, obstacleType: String) -> String {
        // Replace "an obstacle" or "obstacle" with the specific obstacle type
        let obstacleName = obstacleType.lowercased()
        return baseWarning.replacingOccurrences(of: "an obstacle", with: "a \(obstacleName)")
                          .replacingOccurrences(of: "obstacle", with: obstacleName)
    }
}

// MARK: - Preview
#Preview {
    WarningTestView()
}
