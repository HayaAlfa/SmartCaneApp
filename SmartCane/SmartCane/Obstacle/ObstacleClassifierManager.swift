import Foundation
import CoreML      // Apple's machine learning framework
import Vision      // Apple's computer vision framework
import UIKit       // For UIImage processing

// MARK: - Obstacle Classifier Manager
// Manages the CoreML/Vision pipeline for classifying obstacles in images
class ObstacleClassifierManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ObstacleClassifierManager()

    // MARK: - Published state
    @Published var isModelLoaded = false
    @Published var modelLoadingError: String? = nil
    @Published var isClassifying = false

    // MARK: - Private
    private var classificationModel: VNCoreMLModel? = nil
    private let modelName = "ObstacleClassifier"

    private init() { loadModel() }

    // MARK: - Model loading
    private func loadModel() {
        do {
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                throw ObstacleClassifierError.modelNotFound
            }
            let coreMLModel = try MLModel(contentsOf: modelURL)
            classificationModel = try VNCoreMLModel(for: coreMLModel)
            isModelLoaded = true
            modelLoadingError = nil
        } catch {
            isModelLoaded = false
            modelLoadingError = "Failed to load model: \(error.localizedDescription)"
        }
    }

    func reloadModel() { loadModel() }

    // MARK: - Classification
    func classify(image: UIImage, completion: @escaping (String, Double) -> Void) {
        guard isModelLoaded, let model = classificationModel else {
            completion("Error: Model not loaded", 0.0)
            return
        }

        guard let cgImage = image.cgImage else {
            completion("Error: Invalid image format", 0.0)
            return
        }

        isClassifying = true

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isClassifying = false
                if let error = error {
                    completion("Error: \(error.localizedDescription)", 0.0)
                    return
                }
                self?.processClassificationResults(request: request, completion: completion)
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        request.usesCPUOnly = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isClassifying = false
                    completion("Error: \(error.localizedDescription)", 0.0)
                }
            }
        }
    }

    private func processClassificationResults(request: VNRequest, completion: @escaping (String, Double) -> Void) {
        guard let results = request.results as? [VNClassificationObservation], let top = results.first else {
            completion("Error: No results", 0.0)
            return
        }
        completion(top.identifier, Double(top.confidence))
    }

    // MARK: - Utilities
    func isReady() -> Bool { isModelLoaded && classificationModel != nil }

    func getModelStatus() -> String {
        if isModelLoaded { return "✅ Model loaded and ready" }
        if let error = modelLoadingError { return "❌ \(error)" }
        return "⏳ Loading model..."
    }

    func getModelInfo() -> String {
        guard let model = classificationModel else { return "No model loaded" }
        return "Model: \(modelName)\nVision Model: \(type(of: model))"
    }
}

// MARK: - Errors
enum ObstacleClassifierError: Error, LocalizedError {
    case modelNotFound
    case modelLoadFailed
    case classificationFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound: return "AI model file not found in app bundle"
        case .modelLoadFailed: return "Failed to load AI model"
        case .classificationFailed: return "Image classification failed"
        }
    }
}

// MARK: - Mock classification
extension ObstacleClassifierManager {
    func mockClassify(image: UIImage, completion: @escaping (String, Double) -> Void) {
        isClassifying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isClassifying = false
            let mockResults = [
                ("Chair", 0.95), ("Table", 0.87), ("Door", 0.92),
                ("Stairs", 0.89), ("Obstacle", 0.78), ("Clear Path", 0.85)
            ]
            let r = mockResults.randomElement() ?? ("Unknown", 0.5)
            completion(r.0, r.1)
        }
    }
    var shouldUseMock: Bool { !isModelLoaded }
}

