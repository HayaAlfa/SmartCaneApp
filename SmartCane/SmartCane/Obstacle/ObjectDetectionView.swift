import SwiftUI
import CoreML
import Vision

struct ObjectDetectionView: View {
    @State private var showPicker = false
    @State private var pickedImage: UIImage? = nil
    @State private var classificationResult: String = ""
    @State private var confidence: Double = 0.0
    @State private var isClassifying = false
    @State private var detectionHistory: [DetectionRecord] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Simple header
                VStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Object Detection")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Take a photo to identify objects")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Photo picker button
                Button(action: {
                    showPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Pick Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Show selected image and classify button
                if let image = pickedImage {
                    VStack(spacing: 15) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        Button(action: {
                            classifyImage(image: image)
                        }) {
                            HStack {
                                if isClassifying {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text(isClassifying ? "Analyzing..." : "Identify Object")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isClassifying)
                        .padding(.horizontal)
                    }
                }
                
                // Show results
                if !classificationResult.isEmpty {
                    VStack(spacing: 10) {
                        Text("Found:")
                            .font(.headline)
                        
                        Text(classificationResult)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("\(Int(confidence * 100))% confident")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button("Save Result") {
                            saveToHistory()
                        }
                        .buttonStyle(SimpleButtonStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Object Detection")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPicker) {
                PhotoPicker(selectedImage: $pickedImage)
            }
            .onAppear {
                loadDetectionHistory()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func classifyImage(image: UIImage) {
        isClassifying = true
        classificationResult = ""
        confidence = 0.0
        
        ObstacleClassifierManager.shared.classify(image: image) { type, conf in
            DispatchQueue.main.async {
                self.classificationResult = type
                self.confidence = conf
                self.isClassifying = false
                
                if !type.hasPrefix("Error:") {
                    ObstacleLogger.shared.logDetection(
                        obstacleType: type,
                        confidence: conf
                    )
                }
            }
        }
    }
    
    private func saveToHistory() {
        let record = DetectionRecord(
            objectType: classificationResult,
            confidence: confidence,
            timestamp: Date(),
            image: pickedImage
        )
        
        detectionHistory.insert(record, at: 0)
        saveDetectionHistory()
        
        ObstacleLogger.shared.logSave(
            obstacleType: classificationResult,
            confidence: confidence
        )
    }
    
    private func saveDetectionHistory() {
        let metadata = detectionHistory.map { record in
            DetectionRecordMetadata(
                objectType: record.objectType,
                confidence: record.confidence,
                timestamp: record.timestamp
            )
        }
        
        if let encoded = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(encoded, forKey: "DetectionHistory")
        }
    }
    
    private func loadDetectionHistory() {
        if let data = UserDefaults.standard.data(forKey: "DetectionHistory"),
           let metadata = try? JSONDecoder().decode([DetectionRecordMetadata].self, from: data) {
            detectionHistory = metadata.map { meta in
                DetectionRecord(
                    objectType: meta.objectType,
                    confidence: meta.confidence,
                    timestamp: meta.timestamp,
                    image: nil
                )
            }
        }
    }
}

// MARK: - Simple Data Types
struct DetectionRecord: Identifiable {
    let id = UUID()
    let objectType: String
    let confidence: Double
    let timestamp: Date
    let image: UIImage?
}

struct DetectionRecordMetadata: Codable {
    let objectType: String
    let confidence: Double
    let timestamp: Date
}

// MARK: - Simple Button Style
struct SimpleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
#Preview {
    ObjectDetectionView()
}
