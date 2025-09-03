# SmartCane App 📱

A comprehensive iOS application designed to assist users with navigation, obstacle detection, and location management. Built with SwiftUI and modern iOS frameworks.

## 🎯 App Overview

SmartCane is a multi-functional iOS app that combines **location services**, **AI-powered obstacle detection**, **location management**, and **user profile settings** into a clean, tab-based interface. The app is designed to be accessible and user-friendly while providing powerful navigation and safety features.

## 🏗️ Architecture

- **Framework**: SwiftUI (iOS 14+)
- **Language**: Swift 5
- **Design Pattern**: MVVM with ObservableObject
- **Navigation**: TabView with NavigationView
- **Data Persistence**: UserDefaults for simple data storage
- **Location Services**: CoreLocation and MapKit
- **AI/ML**: CoreML and Vision frameworks

## 📱 App Structure

The app is organized into **4 main tabs**, each serving a specific purpose:

### 1. 🗺️ Map Tab (`MapView`)
**Purpose**: Primary navigation interface with real-time location tracking and search functionality.

**Features**:
- **Interactive Map**: Full-screen map using MapKit with user location display
- **Location Services**: GPS tracking with accuracy monitoring and status display
- **Search Functionality**: Search for places using Apple's local search
- **Map Controls**: 
  - Center on user location
  - Toggle between standard and satellite views
  - Follow user movement automatically
- **Location Status**: Real-time GPS accuracy, last update time, and error handling
- **Search Results**: Display search results with tap-to-navigate functionality

**Key Components**:
- `LocationManager`: Handles GPS, permissions, and location updates
- Search bar with location button
- Map type toggle (standard/satellite)
- Location status overlay
- Search results list

---

### 2. 📍 Saved Locations Tab (`SavedLocationsView`)
**Purpose**: Manage and organize user's saved locations with categories and search.

**Features**:
- **Location Management**: Add, edit, and delete saved locations
- **Categorization**: 6 predefined categories (Home, Work, Favorite, Restaurant, Store, Other)
- **Search & Filter**: Search through locations by name, address, or notes
- **Category Filtering**: Filter locations by specific categories
- **Location Details**: Store name, address, GPS coordinates, category, notes, and date added
- **Quick Actions**: Open locations in Maps app, delete locations

**Key Components**:
- `SavedLocation`: Data model with Identifiable and Codable protocols
- `LocationCategory`: Enum with icons and colors for each category
- Search bar with real-time filtering
- Category filter buttons
- Location list with custom row design
- Add location functionality

**Supporting Views**:
- `AddLocationView`: Form to create new saved locations
- `SavedLocationRow`: Individual location display with actions

---

### 3. 🔍 Object Detection Tab (`ObjectDetectionView`)
**Purpose**: AI-powered obstacle detection using photos for enhanced safety.

**Features**:
- **Photo Selection**: Pick photos from user's photo library
- **AI Classification**: Analyze images using CoreML model for obstacle detection
- **Results Display**: Show detected object type and confidence percentage
- **Detection History**: Track previous detections with timestamps
- **Model Status**: Monitor AI model loading and readiness
- **Mock Classification**: Fallback classification when real model isn't available

**Key Components**:
- `ObstacleClassifierManager`: Manages AI model and classification
- `PhotoPicker`: Modern photo selection interface using PhotosUI
- Image display and classification controls
- Results display with confidence metrics
- Detection history with custom rows
- Model status monitoring

**AI Features**:
- CoreML model integration for object classification
- Vision framework for image processing
- Confidence scoring for detection accuracy
- Error handling for model failures

---

### 4. 👤 Profile Tab (`ProfileView`)
**Purpose**: User account management, app settings, and information.

**Features**:
- **User Profile**: Display and edit personal information (name, email, phone)
- **App Settings**: 
  - Notification preferences
  - Privacy and security settings
  - Connection status (Bluetooth, location)
- **App Information**: About section with features, team, and legal info
- **Permission Management**: Quick access to system settings for permissions

**Key Components**:
- Profile header with user information
- Account information section
- Settings toggles and navigation
- Connection status indicators
- App information and legal links

**Supporting Views**:
- `EditProfileView`: Edit user profile information
- `NotificationSettingsView`: Configure notification preferences
- `PrivacySettingsView`: Manage privacy and security settings
- `AboutView`: App information, features, and team details

---

## 🔧 Core Services

### LocationManager
- **GPS Tracking**: Real-time location updates with accuracy monitoring
- **Permission Management**: Handle location permission requests and status
- **Map Integration**: Provide coordinates and region data for map views
- **Error Handling**: Comprehensive error handling for location services
- **Background Safety**: No background location tracking for privacy

### ObstacleClassifierManager
- **AI Model Management**: Load and manage CoreML models
- **Image Classification**: Process images and return object classifications
- **Mock Support**: Provide test results when real model isn't available
- **Performance Optimization**: Use GPU when available for faster processing

### PhotoPicker
- **Modern Interface**: PhotosUI integration for iOS 14+
- **Legacy Support**: Fallback to UIImagePickerController for older iOS
- **Image Processing**: Efficient image loading and handling
- **User Experience**: Single image selection with editing capabilities

## 📊 Data Models

### SavedLocation
```swift
struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: LocationCategory
    var notes: String
    var dateAdded: Date
}
```

### DetectionRecord
```swift
struct DetectionRecord: Identifiable {
    let id = UUID()
    let objectType: String
    let confidence: Double
    let timestamp: Date
    let image: UIImage?
}
```

## 🎨 UI/UX Features

- **Tab-Based Navigation**: Intuitive bottom tab bar for easy switching
- **Material Design**: Translucent backgrounds and modern iOS styling
- **Responsive Layout**: Adapts to different screen sizes and orientations
- **Accessibility**: Proper labels, contrast, and touch targets
- **Loading States**: Progress indicators and status messages
- **Error Handling**: User-friendly error messages and recovery options

## 🚀 Getting Started

1. **Clone the repository**
2. **Open in Xcode** (requires Xcode 12+)
3. **Build and run** on iOS 14+ device or simulator
4. **Grant permissions** for location and photo library access
5. **Explore the tabs** to discover all features

## 📱 System Requirements

- **iOS Version**: 14.0 or later
- **Device**: iPhone or iPad
- **Permissions**: Location services, photo library access
- **Features**: GPS, camera (for photo selection)

## 🔒 Privacy & Permissions

The app requests the following permissions:
- **Location**: For navigation and GPS features
- **Photo Library**: For obstacle detection photos
- **Notifications**: For app alerts and reminders

All data is stored locally on the device using UserDefaults. No personal information is transmitted to external servers.

## 🛠️ Development Notes

- **SwiftUI Best Practices**: Modern SwiftUI patterns and property wrappers
- **MVVM Architecture**: Clean separation of concerns
- **Error Handling**: Comprehensive error handling throughout
- **Performance**: Efficient data loading and UI updates
- **Testing**: Mock data support for development and testing

## 📚 Learning Resources

This codebase demonstrates:
- SwiftUI fundamentals and advanced patterns
- CoreLocation and MapKit integration
- CoreML and Vision framework usage
- UserDefaults for data persistence
- Photo picker implementation
- Tab-based navigation
- Form handling and validation
- Permission management
- Error handling and user feedback

## 🤝 Contributing

This is a learning project demonstrating iOS development concepts. Feel free to:
- Study the code structure
- Experiment with modifications
- Learn SwiftUI patterns
- Understand iOS framework integration

## 📄 License

This project is for educational purposes. All code is provided as-is for learning iOS development concepts.

---

**Built with ❤️ using SwiftUI and modern iOS frameworks**
