import SwiftUI
import PhotosUI  // Apple's photo picker framework for iOS 14+

// MARK: - Photo Picker View
// This view provides a modern photo selection interface using PhotosUI
struct PhotoPicker: UIViewControllerRepresentable {
    
    // MARK: - Properties
    @Binding var selectedImage: UIImage?  // Binding to store the selected image
    
    // MARK: - UIViewControllerRepresentable Methods
    // These methods are required to bridge SwiftUI with UIKit
    
    // Create the UIKit view controller
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configure photo picker settings
        var configuration = PHPickerConfiguration()
        configuration.filter = .images                    // Only show images (no videos)
        configuration.selectionLimit = 1                  // Allow selecting only one image
        configuration.preferredAssetRepresentationMode = .current  // Use highest quality available
        
        // Create the photo picker with our configuration
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator            // Set delegate to handle selection
        
        print("📸 PhotoPicker created with image filter and single selection")
        return picker
    }
    
    // Update the UIKit view controller (not needed for photo picker)
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed for photo picker
    }
    
    // MARK: - Coordinator
    // Coordinator handles communication between UIKit and SwiftUI
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)  // Pass self reference to coordinator
    }
    
    // MARK: - Coordinator Class
    // This class handles the photo picker delegate methods
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        let parent: PhotoPicker  // Reference to parent PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        // MARK: - Photo Selection Handler
        // Called when user selects photos in the picker
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            print("📸 Photo selection completed with \(results.count) results")
            
            // Dismiss the photo picker
            picker.dismiss(animated: true)
            
            // Handle the selected photo
            guard let result = results.first else {
                print("📸 No photo selected")
                return
            }
            
            // Load the selected image
            loadImage(from: result)
        }
        
        // MARK: - Image Loading
        // Loads the selected image from the photo picker result
        private func loadImage(from result: PHPickerResult) {
            
            // Check if the result can provide an image
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                
                print("🔄 Loading selected image...")
                
                // Load the image asynchronously
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    
                    DispatchQueue.main.async {  // Update UI on main thread
                        if let error = error {
                            print("❌ Failed to load image: \(error)")
                            return
                        }
                        
                        if let image = image as? UIImage {
                            print("✅ Image loaded successfully: \(image.size)")
                            
                            // Store the selected image in the parent's binding
                            self?.parent.selectedImage = image
                            
                        } else {
                            print("❌ Failed to cast image to UIImage")
                        }
                    }
                }
                
            } else {
                print("❌ Selected item cannot provide UIImage")
            }
        }
    }
}

// MARK: - Legacy Photo Picker (for iOS 13 compatibility)
// This provides a fallback for older iOS versions if needed
struct LegacyPhotoPicker: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true  // Allow user to crop/edit the image
        
        print("📸 Legacy PhotoPicker created with photo library source")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        let parent: LegacyPhotoPicker
        
        init(_ parent: LegacyPhotoPicker) {
            self.parent = parent
        }
        
        // Handle image selection
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            print("📸 Legacy photo picker selection completed")
            
            // Get the selected image (edited version if user cropped it)
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImage = image
                print("✅ Edited image selected: \(image.size)")
            } else if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                print("✅ Original image selected: \(image.size)")
            }
            
            // Dismiss the picker
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Handle cancellation
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 Photo picker cancelled by user")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Photo Picker Wrapper
// This provides a unified interface that automatically chooses the best picker
struct SmartPhotoPicker: View {
    
    @Binding var selectedImage: UIImage?
    @State private var showingPicker = false
    
    var body: some View {
        Button("Select Photo") {
            showingPicker = true
        }
        .sheet(isPresented: $showingPicker) {
            // Use the modern PhotosUI picker for iOS 14+
            if #available(iOS 14.0, *) {
                PhotoPicker(selectedImage: $selectedImage)
            } else {
                // Fallback to legacy picker for iOS 13
                LegacyPhotoPicker(selectedImage: $selectedImage)
            }
        }
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    SmartPhotoPicker(selectedImage: .constant(nil))
}
