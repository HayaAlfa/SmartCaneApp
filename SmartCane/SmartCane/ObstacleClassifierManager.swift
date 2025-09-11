<<<<<<< HEAD
//
//  ObstacleClassifierManager.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 8/30/25.
//

import Foundation
import CoreML
import Vision
import UIKit

class ObstacleClassifierManager {
    
    static let shared = ObstacleClassifierManager()
    
    private var model: VNCoreMLModel?
    private var isModelLoaded = false
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        print("🔍 Starting model loading process...")
        
        // First, let's check what's in the bundle
        let bundlePath = Bundle.main.bundlePath
        print("📁 Bundle path: \(bundlePath)")
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            print("📦 Bundle contents: \(contents)")
        } catch {
            print("❌ Failed to list bundle contents: \(error)")
        }
        
        do {
            // Try to load the compiled model first (.mlmodelc)
            guard let url = Bundle.main.url(forResource: "ObstacleClassifier", withExtension: "mlmodelc") else {
                print("❌ ObstacleClassifier.mlmodelc not found in bundle")
                
                // Fallback: try the original .mlpackage
                guard let packageUrl = Bundle.main.url(forResource: "ObstacleClassifier", withExtension: "mlpackage") else {
                    print("❌ ObstacleClassifier.mlpackage also not found in bundle")
                    print("🔍 Checking for alternative paths...")
                    
                    // Try to find any mlpackage or mlmodelc files
                    let enumerator = FileManager.default.enumerator(atPath: bundlePath)
                    while let filePath = enumerator?.nextObject() as? String {
                        if filePath.hasSuffix(".mlpackage") || filePath.hasSuffix(".mlmodelc") {
                            print("📦 Found model file: \(filePath)")
                        }
                    }
                    return
                }
                
                print("✅ Found mlpackage at: \(packageUrl)")
                let coreMLModel = try MLModel(contentsOf: packageUrl)
                print("✅ CoreML model loaded successfully from mlpackage")
                
                model = try VNCoreMLModel(for: coreMLModel)
                isModelLoaded = true
                print("✅ VNCoreMLModel created successfully")
                print("✅ ObstacleClassifier loaded and ready")
                return
            }
            
            print("✅ Found compiled model at: \(url)")
            let coreMLModel = try MLModel(contentsOf: url)
            print("✅ CoreML model loaded successfully from mlmodelc")
            
            model = try VNCoreMLModel(for: coreMLModel)
            isModelLoaded = true
            print("✅ VNCoreMLModel created successfully")
            print("✅ ObstacleClassifier loaded and ready")
            
        } catch {
            print("❌ Failed to load ObstacleClassifier: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
        }
    }
    
    func classify(image: UIImage, completion: @escaping (String, Double) -> Void) {
        guard isModelLoaded, let model = model else {
            print("❌ Model not loaded. isModelLoaded: \(isModelLoaded), model: \(model != nil)")
=======
import Foundation
import CoreML      // Apple's machine learning framework
import Vision      // Apple's computer vision framework
import UIKit       // For UIImage processing

// MARK: - Obstacle Classifier Manager
// This class manages the AI model for classifying objects in images
class ObstacleClassifierManager: ObservableObject {
    
    // MARK: - Singleton Pattern
    // Shared instance that can be used across the app
    static let shared = ObstacleClassifierManager()
    
    // MARK: - Published Properties
    // These properties automatically update the UI when they change
    @Published var isModelLoaded = false           // Whether the AI model is ready to use
    @Published var modelLoadingError: String? = nil // Error message if model fails to load
    @Published var isClassifying = false           // Whether currently processing an image
    
    // MARK: - Private Properties
    private var classificationModel: VNCoreMLModel? = nil  // The loaded AI model
    private let modelName = "ObstacleClassifier"           // Name of the ML model file
    
    // MARK: - Initialization
    private init() {
        loadModel()  // Try to load the AI model when class is created
    }
    
    // MARK: - Model Management
    
    // Load the machine learning model for object classification
    private func loadModel() {
        print("🧠 Loading ObstacleClassifier model...")
        
        do {
            // Try to load the model from the app bundle
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                throw ObstacleClassifierError.modelNotFound
            }
            
            // Create a CoreML model from the URL
            let coreMLModel = try MLModel(contentsOf: modelURL)
            
            // Create a Vision model wrapper for image processing
            classificationModel = try VNCoreMLModel(for: coreMLModel)
            
            isModelLoaded = true
            modelLoadingError = nil
            
            print("✅ ObstacleClassifier model loaded successfully")
            
        } catch {
            isModelLoaded = false
            modelLoadingError = "Failed to load model: \(error.localizedDescription)"
            
            print("❌ Failed to load ObstacleClassifier model: \(error)")
        }
    }
    
    // Reload the model (useful for troubleshooting)
    func reloadModel() {
        print("🔄 Reloading ObstacleClassifier model...")
        loadModel()
    }
    
    // MARK: - Object Classification
    
    // Classify objects in a given image
    func classify(image: UIImage, completion: @escaping (String, Double) -> Void) {
        guard isModelLoaded, let model = classificationModel else {
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
            completion("Error: Model not loaded", 0.0)
            return
        }
        
<<<<<<< HEAD
        guard let ciImage = CIImage(image: image) else {
            print("❌ Failed to convert UIImage to CIImage")
            completion("Error: Invalid image", 0.0)
            return
        }
        
        print("🔍 Starting classification...")
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("❌ Classification error: \(error)")
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)", 0.0)
                }
                return
            }
            
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                print("✅ Classification result: \(topResult.identifier) (\(topResult.confidence))")
                DispatchQueue.main.async {
                    completion(topResult.identifier, Double(topResult.confidence))
                }
            } else {
                print("⚠️ No classification results")
                DispatchQueue.main.async {
                    completion("Unknown", 0.0)
                }
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
=======
        guard let cgImage = image.cgImage else {
            completion("Error: Invalid image format", 0.0)
            return
        }
        
        isClassifying = true
        print("🔍 Starting image classification...")
        
        // Create a Vision request for object classification
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isClassifying = false
                
                if let error = error {
                    print("❌ Classification error: \(error)")
                    completion("Error: \(error.localizedDescription)", 0.0)
                    return
                }
                
                // Process the classification results
                self?.processClassificationResults(request: request, completion: completion)
            }
        }
        
        // Configure the request for best results
        request.imageCropAndScaleOption = .centerCrop  // Crop image to center
        request.usesCPUOnly = false                     // Use GPU if available for better performance
        
        // Create a handler to process the image
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the classification on a background queue
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
<<<<<<< HEAD
                print("❌ Failed to perform classification: \(error)")
                DispatchQueue.main.async {
=======
                DispatchQueue.main.async {
                    self.isClassifying = false
                    print("❌ Failed to perform classification: \(error)")
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    completion("Error: \(error.localizedDescription)", 0.0)
                }
            }
        }
    }
    
<<<<<<< HEAD
    func isReady() -> Bool {
        return isModelLoaded && model != nil
    }
}

=======
    // Process the results from the AI model
    private func processClassificationResults(request: VNRequest, completion: @escaping (String, Double) -> Void) {
        guard let results = request.results as? [VNClassificationObservation] else {
            completion("Error: No classification results", 0.0)
            return
        }
        
        // Get the top result (highest confidence)
        guard let topResult = results.first else {
            completion("Error: Empty results", 0.0)
            return
        }
        
        let objectType = topResult.identifier
        let confidence = Double(topResult.confidence)
        
        print("✅ Classification result: \(objectType) (\(confidence * 100)%)")
        
        // Return the result to the caller
        completion(objectType, confidence)
    }
    
    // MARK: - Utility Functions
    
    // Check if the model is ready for classification
    func isReady() -> Bool {
        return isModelLoaded && classificationModel != nil
    }
    
    // Get the current model status as a string
    func getModelStatus() -> String {
        if isModelLoaded {
            return "✅ Model loaded and ready"
        } else if let error = modelLoadingError {
            return "❌ \(error)"
        } else {
            return "⏳ Loading model..."
        }
    }
    
    // Get model information for debugging
    func getModelInfo() -> String {
        guard let model = classificationModel else {
            return "No model loaded"
        }
        
        return "Model: \(modelName)\nVision Model: \(type(of: model))"
    }
}

// MARK: - Custom Errors
// Define specific error types for better error handling
enum ObstacleClassifierError: Error, LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case classificationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "AI model file not found in app bundle"
        case .modelLoadFailed:
            return "Failed to load AI model"
        case .classificationFailed:
            return "Image classification failed"
        }
    }
}

// MARK: - Mock Classification (for testing without ML model)
// This provides fake results when the real model isn't available
extension ObstacleClassifierManager {
    
    // Mock classification for testing purposes
    func mockClassify(image: UIImage, completion: @escaping (String, Double) -> Void) {
        print("🎭 Using mock classification (no real AI model)")
        
        isClassifying = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isClassifying = false
            
            // Return a random mock result
            let mockResults = [
                ("Chair", 0.95),
                ("Table", 0.87),
                ("Door", 0.92),
                ("Stairs", 0.89),
                ("Obstacle", 0.78),
                ("Clear Path", 0.85)
            ]
            
            let randomResult = mockResults.randomElement() ?? ("Unknown", 0.5)
            completion(randomResult.0, randomResult.1)
        }
    }
    
    // Check if we should use mock classification
    var shouldUseMock: Bool {
        return !isModelLoaded
    }
}
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
