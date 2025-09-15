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
            completion("Error: Model not loaded", 0.0)
            return
        }
        
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
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform classification: \(error)")
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)", 0.0)
                }
            }
        }
    }
    
    func isReady() -> Bool {
        return isModelLoaded && model != nil
    }
}

