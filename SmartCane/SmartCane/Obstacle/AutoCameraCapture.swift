//
//  AutoCameraCapture.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 9/27/25.
//

import Foundation
import AVFoundation
import UIKit

class AutoCameraCapture: NSObject, ObservableObject {
    static let shared = AutoCameraCapture()
    
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .photo
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            errorMessage = "Cannot access camera"
            return
        }
        
        captureSession.addInput(videoInput)
        videoDeviceInput = videoInput
        
        // Add photo output
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput,
              captureSession.canAddOutput(photoOutput) else {
            errorMessage = "Cannot setup photo output"
            return
        }
        
        captureSession.addOutput(photoOutput)
    }
    
    func startSession() {
        guard let captureSession = captureSession else { return }
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                print("📸 Auto camera session started")
            }
        }
    }
    
    func stopSession() {
        guard let captureSession = captureSession else { return }
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.stopRunning()
                print("📸 Auto camera session stopped")
            }
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else {
            errorMessage = "Photo output not available"
            return
        }
        
        isCapturing = true
        errorMessage = nil
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        print("📸 Auto-capturing photo...")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension AutoCameraCapture: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
            
            if let error = error {
                self.errorMessage = "Photo capture failed: \(error.localizedDescription)"
                print("❌ Auto photo capture error: \(error)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.errorMessage = "Failed to process captured image"
                print("❌ Failed to process auto-captured image data")
                return
            }
            
            self.capturedImage = image
            print("✅ Auto photo captured successfully: \(image.size)")
        }
    }
}


