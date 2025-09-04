import SwiftUI
import CoreML      // Apple's machine learning framework
import Vision      // Apple's computer vision framework

struct ObjectDetectionView: View {
    // MARK: - State Properties
    // These properties control the UI state and store user data
    @StateObject private var dataManager = TempDataManager.shared  // Temporary data manager
    @State private var showPicker = false              // Controls photo picker sheet
    @State private var pickedImage: UIImage? = nil     // Stores the selected photo
    @State private var classificationResult: String = "" // Stores AI classification result
    @State private var confidence: Double = 0.0        // Stores confidence percentage (0.0 to 1.0)
    @State private var isClassifying = false           // Shows loading state during AI processing
    @State private var modelStatus: String = "Checking..." // Shows if AI model is ready
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - AI Model Status Section
                    // Shows whether the machine learning model is loaded and ready
                    modelStatusSection
                    
                    // MARK: - Photo Classification Section
                    // Main interface for taking photos and classifying objects
                    photoClassificationSection
                    
                                    // MARK: - Detection History Section
                // Shows previous detection results (only if there are any)
                if !dataManager.detectionRecords.isEmpty {
                    detectionHistorySection
                }
                }
                .padding()
            }
            .navigationTitle("Object Detection")  // Navigation bar title
            .navigationBarTitleDisplayMode(.large)  // Large title style
            .sheet(isPresented: $showPicker) {
                // Photo picker sheet for selecting images from library
                PhotoPicker(selectedImage: $pickedImage)
            }
            .onAppear {
                // Check if AI model is ready when view appears
                testModelLoading()
            }
        }
    }
    
    // MARK: - AI Model Status Section
    // This section shows the status of the machine learning model
    private var modelStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")  // Brain icon for AI
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("AI Model Status")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                // Show current model status
                HStack {
                    Text("Model:")
                        .font(.subheadline)
                    Spacer()
                    Text(modelStatus)
                        .font(.subheadline)
                        .foregroundColor(modelStatus.contains("✅") ? .green : .red)
                }
                
                // Show if model is ready for classification
                HStack {
                    Text("Ready:")
                        .font(.subheadline)
                    Spacer()
                    Text(ObstacleClassifierManager.shared.isReady() ? "✅ Yes" : "❌ No")
                        .font(.subheadline)
                        .foregroundColor(ObstacleClassifierManager.shared.isReady() ? .green : .red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Button to test if model can be loaded
            Button("Test Model Loading") {
                testModelLoading()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Photo Classification Section
    // Main interface for object detection workflow
    private var photoClassificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "camera.viewfinder")  // Camera icon
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Obstacle Detection")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Button to open photo picker
            Button(action: {
                showPicker = true  // Show photo picker sheet
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Pick Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // MARK: - Selected Image Display and Classification
            // This section only shows when a photo has been selected
            if let image = pickedImage {
                VStack(spacing: 12) {
                    // Display the selected image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    // Button to start AI classification
                    Button(action: {
                        classifyImage(image: image)  // Start the AI classification process
                    }) {
                        HStack {
                            if isClassifying {
                                // Show loading spinner during classification
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                // Show magnifying glass icon when ready
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isClassifying ? "Classifying..." : "Classify Object")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isClassifying || !ObstacleClassifierManager.shared.isReady())  // Disable if busy or model not ready
                    
                    // MARK: - Classification Results Display
                    // This section shows the AI classification results
                    if !classificationResult.isEmpty {
                        VStack(spacing: 12) {
                            // Success indicator
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Detection Complete!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            // Object type result
                            VStack(spacing: 8) {
                                Text("Object Type:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(classificationResult)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            // Confidence percentage
                            VStack(spacing: 8) {
                                Text("Confidence:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(String(format: "%.1f%%", confidence * 100))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            // Button to save detection to history
                            Button(action: {
                                saveToHistory()
                            }) {
                                HStack {
                                    Image(systemName: "bookmark")
                                    Text("Save to History")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Detection History Section
    // Shows a list of previous object detections
    private var detectionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")  // History icon
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("Detection History")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVStack(spacing: 8) {
                // Show last 5 detection results
                ForEach(dataManager.detectionRecords.prefix(5)) { record in
                    DetectionHistoryRow(record: record)
                }
            }
            
            // Show "View All" button if there are more than 5 detections
            if dataManager.detectionRecords.count > 5 {
                Button("View All (\(dataManager.detectionRecords.count))") {
                    // Could navigate to a full history view in the future
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Test if the AI model can be loaded successfully
    private func testModelLoading() {
        print("🧪 Testing model loading...")
        modelStatus = "Testing..."
        
        if ObstacleClassifierManager.shared.isReady() {
            modelStatus = "✅ Model loaded successfully"
            print("✅ Model is ready for classification")
        } else {
            modelStatus = "❌ Model failed to load"
            print("❌ Model is not ready")
        }
    }
    
    // Start the AI classification process for a selected image
    private func classifyImage(image: UIImage) {
        isClassifying = true
        classificationResult = ""
        confidence = 0.0
        
        print("🔍 Starting classification for image...")
        print("🔍 Model ready: \(ObstacleClassifierManager.shared.isReady())")
        
        // Use the shared AI manager to classify the image
        ObstacleClassifierManager.shared.classify(image: image) { type, conf in
            DispatchQueue.main.async {  // Update UI on main thread
                self.classificationResult = type
                self.confidence = conf
                self.isClassifying = false
                
                if type.hasPrefix("Error:") {
                    print("❌ Classification failed: \(type)")
                } else {
                    print("✅ Classification successful: \(type) (\(conf * 100)%)")
                }
            }
        }
    }
    
    // Save the current detection result to history
    private func saveToHistory() {
        let newRecord = TempDetectionRecord(
            objectType: classificationResult,
            confidence: confidence,
            dateCreated: Date()
        )
        dataManager.detectionRecords.append(newRecord)
        dataManager.saveData()
    }
    

}



// MARK: - Detection History Row Component
// Shows a single detection record in the history list
struct DetectionHistoryRow: View {
    let record: TempDetectionRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon to represent detection
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                // Object type that was detected
                Text(record.objectType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Confidence percentage
                Text("\(String(format: "%.1f%%", record.confidence * 100)) confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time when detection was made
            Text(record.dateCreated, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    ObjectDetectionView()
}
