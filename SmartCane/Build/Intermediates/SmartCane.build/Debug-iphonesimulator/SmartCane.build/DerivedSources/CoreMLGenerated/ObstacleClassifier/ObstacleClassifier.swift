//
// ObstacleClassifier.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
class ObstacleClassifierInput : MLFeatureProvider {

    /// input_1 as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
    var input_1: CVPixelBuffer

    var featureNames: Set<String> { ["input_1"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input_1" {
            return MLFeatureValue(pixelBuffer: input_1)
        }
        return nil
    }

    init(input_1: CVPixelBuffer) {
        self.input_1 = input_1
    }

    convenience init(input_1With input_1: CGImage) throws {
        self.init(input_1: try MLFeatureValue(cgImage: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }

    convenience init(input_1At input_1: URL) throws {
        self.init(input_1: try MLFeatureValue(imageAt: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }

    func setInput_1(with input_1: CGImage) throws  {
        self.input_1 = try MLFeatureValue(cgImage: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

    func setInput_1(with input_1: URL) throws  {
        self.input_1 = try MLFeatureValue(imageAt: input_1, pixelsWide: 224, pixelsHigh: 224, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

}


/// Model Prediction Output Type
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
class ObstacleClassifierOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// classLabel as string value
    var classLabel: String {
        provider.featureValue(for: "classLabel")!.stringValue
    }

    /// classLabel_probs as dictionary of strings to doubles
    var classLabel_probs: [String : Double] {
        provider.featureValue(for: "classLabel_probs")!.dictionaryValue as! [String : Double]
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(classLabel: String, classLabel_probs: [String : Double]) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["classLabel" : MLFeatureValue(string: classLabel), "classLabel_probs" : MLFeatureValue(dictionary: classLabel_probs as [AnyHashable : NSNumber])])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
class ObstacleClassifier {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "ObstacleClassifier", withExtension:"mlmodelc")!
    }

    /**
        Construct ObstacleClassifier instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of ObstacleClassifier.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `ObstacleClassifier.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct ObstacleClassifier instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct ObstacleClassifier instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<ObstacleClassifier, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct ObstacleClassifier instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> ObstacleClassifier {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct ObstacleClassifier instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<ObstacleClassifier, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(ObstacleClassifier(model: model)))
            }
        }
    }

    /**
        Construct ObstacleClassifier instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> ObstacleClassifier {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return ObstacleClassifier(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as ObstacleClassifierInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ObstacleClassifierOutput
    */
    func prediction(input: ObstacleClassifierInput) throws -> ObstacleClassifierOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as ObstacleClassifierInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ObstacleClassifierOutput
    */
    func prediction(input: ObstacleClassifierInput, options: MLPredictionOptions) throws -> ObstacleClassifierOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return ObstacleClassifierOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as ObstacleClassifierInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ObstacleClassifierOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: ObstacleClassifierInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> ObstacleClassifierOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return ObstacleClassifierOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - input_1: color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as ObstacleClassifierOutput
    */
    func prediction(input_1: CVPixelBuffer) throws -> ObstacleClassifierOutput {
        let input_ = ObstacleClassifierInput(input_1: input_1)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [ObstacleClassifierInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [ObstacleClassifierOutput]
    */
    func predictions(inputs: [ObstacleClassifierInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [ObstacleClassifierOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [ObstacleClassifierOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  ObstacleClassifierOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
