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
    @State private var bluetoothSignal: String = ""
    @State private var lastReceivedTime: Date?
    @State private var processStartTime: Date?
    @State private var isProcessingImage = false
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
                    
                    Text("Warning Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Test ESP32 Bluetooth signal parsing")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                
                // Manual Signal Input section
                VStack(spacing: 10) {
                    Text("Manual Signal Input")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        TextField("e.g. F:20, L:15, STOP", text: $signalText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                parseSignal()
                            }
                        
                        Button("Send") {
                            parseSignal()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(signalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(signalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    }
                    .padding(.horizontal)
                }
                
                // Bluetooth Signal Display section
                VStack(spacing: 10) {
                    Text("Bluetooth Signal Received")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if bluetoothSignal.isEmpty {
                            Text("No signal received yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            HStack {
                                Text("Signal:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(bluetoothSignal)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            if let time = lastReceivedTime {
                                Text("Received: \(time.formatted(date: .omitted, time: .standard))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
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
                
                // Warning Output section
                VStack(spacing: 10) {
                    Text("Warning Output")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    if showingWarning {
                        VStack(spacing: 12) {
                            // Warning message
                            Text(currentWarning)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                            
                            // Show obstacle details if available
                            if let obstacle = currentObstacle {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Detected Obstacle:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack {
                                        Text("Type:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(obstacle.type)
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack {
                                        Text("Distance:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(String(format: "%.1f", obstacle.distance)) cm")
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack {
                                        Text("Detected:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(obstacle.detectedAt.formatted(date: .omitted, time: .standard))
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Text("No warning generated yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                }
                .padding(.bottom, 50) // Extra padding at bottom for keyboard
            }
            .navigationTitle("Warning Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Camera session will start only when needed (not immediately)
                // Bluetooth listener removed - not needed for manual input
            }
            .onDisappear {
                // Stop camera if it's running
                autoCamera.stopSession()
                // Bluetooth listener removed - not needed for manual input
            }
            // onChange removed - using manual delay instead to prevent double processing
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupBluetoothListener() {
        NotificationCenter.default.addObserver(
            forName: .obstacleDetected,
            object: nil,
            queue: .main
        ) { notification in
            // Only process if this is a real Bluetooth signal (has rawMessage)
            // Skip if this is just a notification from manual input processing
            if let rawMessage = notification.userInfo?["rawMessage"] as? String {
                self.bluetoothSignal = rawMessage
                self.lastReceivedTime = Date()
                
                // Automatically process the Bluetooth signal
                self.processBluetoothSignal(rawMessage)
            }
        }
    }
    
    private func removeBluetoothListener() {
        NotificationCenter.default.removeObserver(self, name: .obstacleDetected, object: nil)
    }
    
    private func processBluetoothSignal(_ signal: String) {
        print(String(repeating: "-", count: 60))
        processStartTime = Date()
        print("📡 Processing Bluetooth signal: \(signal)")
        
        // Process the signal same way as manual input
        currentSignal = signal
        isProcessing = true
        showingWarning = false
        currentObstacle = nil
        
        // Start camera session
        print("📸 Starting camera session...")
        autoCamera.startSession()
        
        // Wait a moment for camera to initialize, then capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📸 Calling autoCamera.capturePhoto()...")
            self.autoCamera.capturePhoto()
            
            // Wait for photo capture and then process
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let image = self.autoCamera.capturedImage {
                    print("📸 Photo captured, processing...")
                    self.capturedImage = image
                    self.processCapturedImage()
                } else {
                    print("❌ No image captured after 2 seconds")
                    self.isProcessing = false
                    
                    // Still show warning without image classification
                    let warning = self.sensorProcessor.receiveSignal(signal)
                    self.currentWarning = warning
                    self.showingWarning = true
                    
                    // Stop camera session
                    self.autoCamera.stopSession()
                    
                    self.printTotalTime()
                }
            }
        }
    }
    
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
        
        print(String(repeating: "-", count: 60))
        processStartTime = Date()
        print("📝 Processing Manual signal: \(signal)")
        
        // Valid signal received - trigger auto camera capture
        currentSignal = signal // Store the signal for later processing
        isProcessing = true
        showingWarning = false
        currentObstacle = nil
        
        // Clear the input field
        signalText = ""
        
        // Start camera session
        print("📸 Starting camera session...")
        autoCamera.startSession()
        
        // Wait a moment for camera to initialize, then capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📸 Calling autoCamera.capturePhoto()...")
            self.autoCamera.capturePhoto()
            
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
                    
                    // Stop camera session
                    self.autoCamera.stopSession()
                    
                    self.printTotalTime()
                }
            }
        }
    }
    
    private func processCapturedImage() {
        guard let image = capturedImage else { return }
        guard !isProcessingImage else { 
            print("🔍 Already processing image, skipping...")
            return 
        }
        
        isProcessingImage = true
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
                
                // Save to Supabase using Pipeline
                Task {
                    await Pipeline.shared.handleIncomingObstacle(
                        distance: Int(distance),
                        direction: self.extractDirectionFromSignal(self.currentSignal),
                        obstacleType: objectType,  // AI-classified obstacle type
                        confidence: confidence
                    )
                    
                    if let error = Pipeline.shared.appError {
                        print("❌ Failed to save to Supabase: \(error.localizedDescription)")
                    } else {
                        print("✅ Saved to Supabase successfully")
                    }
                }
                
                // Stop camera session after processing is complete
                print("📸 Stopping camera session...")
                self.autoCamera.stopSession()
                
                // Print total time
                self.printTotalTime()
                
                // Reset processing flag
                self.isProcessingImage = false
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
    
    private func extractDirectionFromSignal(_ signal: String) -> String {
        if signal.hasPrefix("F:") { return "front" }
        if signal.hasPrefix("L:") { return "left" }
        if signal.hasPrefix("R:") { return "right" }
        if signal.hasPrefix("B:") { return "back" }
        return "front" // default
    }
    
    private func integrateObstacleType(baseWarning: String, obstacleType: String) -> String {
        // Replace "an obstacle" or "obstacle" with the specific obstacle type
        let obstacleName = obstacleType.lowercased()
        return baseWarning.replacingOccurrences(of: "an obstacle", with: "a \(obstacleName)")
                          .replacingOccurrences(of: "obstacle", with: obstacleName)
    }
    
    private func printTotalTime() {
        guard let startTime = processStartTime else { return }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        
        print("⏱️  Total time for this process: \(String(format: "%.2f", totalTime)) seconds")
        print(String(repeating: "-", count: 60))
    }
}

// MARK: - Preview
#Preview {
    WarningTestView()
}
