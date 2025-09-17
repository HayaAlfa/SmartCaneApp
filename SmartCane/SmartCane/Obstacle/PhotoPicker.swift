//
//  PhotoPicker.swift
//  SmartCane
//
//  Created by Thu Hieu Truong on 8/30/25.
//

import SwiftUI
import PhotosUI

// MARK: - Photo Picker
// This is a SwiftUI wrapper around PHPickerViewController
// It allows users to select photos from their photo library for object detection
struct PhotoPicker: UIViewControllerRepresentable {
    // MARK: - Binding Properties
    // @Binding creates a two-way connection between this view and its parent
    // When user selects a photo, it updates the parent view's selectedImage property
    @Binding var selectedImage: UIImage?
    
    // MARK: - UIViewControllerRepresentable Methods
    // These methods are required to bridge UIKit (PHPickerViewController) with SwiftUI
    
    // Creates the PHPickerViewController with custom configuration
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // MARK: - Picker Configuration
        // Configure the photo picker to only show images and allow single selection
        var config = PHPickerConfiguration()
        config.filter = .images          // Only show images (no videos)
        config.selectionLimit = 1        // Allow only one photo to be selected
        
        // Create the picker with our configuration
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator  // Set our coordinator as the delegate
        return picker
    }
    
    // Called when SwiftUI needs to update the view controller
    // In this case, we don't need to do anything special
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    // Creates the coordinator that handles communication between UIKit and SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator Class
    // The coordinator acts as a bridge between PHPickerViewController (UIKit) and SwiftUI
    // It implements PHPickerViewControllerDelegate to handle photo selection
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        // MARK: - Properties
        let parent: PhotoPicker  // Reference to the parent PhotoPicker view
        
        // MARK: - Initializer
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        // MARK: - PHPickerViewControllerDelegate Method
        // This method is called when the user finishes picking photos
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker view
            picker.dismiss(animated: true)
            
            // Check if user selected a photo and if it can be loaded as UIImage
            guard let provider = results.first?.itemProvider, 
                  provider.canLoadObject(ofClass: UIImage.self) else { 
                return  // Exit if no valid photo was selected
            }
            
            // Load the selected image asynchronously
            provider.loadObject(ofClass: UIImage.self) { image, error in
                // Update the UI on the main thread (required for UI updates)
                DispatchQueue.main.async {
                    // Set the selected image in the parent view
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

