import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
<<<<<<< HEAD
                // App Icon and Name
                VStack(spacing: 16) {
=======
                // MARK: - App Icon and Name Section
                // Displays the app's visual identity and version information
                VStack(spacing: 16) {
                    // MARK: - App Icon
                    // Large app icon using SF Symbols (in a real app, this would be the actual app icon)
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    Image(systemName: "figure.walk.cane")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
<<<<<<< HEAD
=======
                    // MARK: - App Name
                    // The main app title
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    Text("SmartCane")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
<<<<<<< HEAD
=======
                    // MARK: - App Version
                    // Current version number
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
<<<<<<< HEAD
                // App Description
=======
                // MARK: - App Description Section
                // Explains what the app does and its purpose
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("About SmartCane")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SmartCane is an innovative mobile application designed to assist users with visual impairments and mobility challenges. The app combines advanced AI technology with location services to provide real-time obstacle detection and navigation assistance.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                
<<<<<<< HEAD
                // Features
=======
                // MARK: - Key Features Section
                // Highlights the main capabilities of the app
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
<<<<<<< HEAD
                        FeatureRow(icon: "map", title: "Real-time Navigation", description: "GPS-based location tracking and route guidance")
                        FeatureRow(icon: "camera.viewfinder", title: "Obstacle Detection", description: "AI-powered object recognition and classification")
                        FeatureRow(icon: "mappin.and.ellipse", title: "Saved Locations", description: "Store and manage frequently visited places")
                        FeatureRow(icon: "bell", title: "Smart Alerts", description: "Customizable notifications for safety and convenience")
                    }
                }
                
                // Technology
=======
                        // MARK: - Real-time Navigation Feature
                        FeatureRow(
                            icon: "map",
                            title: "Real-time Navigation",
                            description: "GPS-based location tracking and route guidance"
                        )
                        
                        // MARK: - Obstacle Detection Feature
                        FeatureRow(
                            icon: "camera.viewfinder",
                            title: "Obstacle Detection",
                            description: "AI-powered object recognition and classification"
                        )
                        
                        // MARK: - Saved Locations Feature
                        FeatureRow(
                            icon: "mappin.and.ellipse",
                            title: "Saved Locations",
                            description: "Store and manage frequently visited places"
                        )
                        
                        // MARK: - Smart Alerts Feature
                        FeatureRow(
                            icon: "bell",
                            title: "Smart Alerts",
                            description: "Customizable notifications for safety and convenience"
                        )
                    }
                }
                
                // MARK: - Technology Section
                // Shows the technical frameworks and technologies used
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("Technology")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
<<<<<<< HEAD
                        TechRow(icon: "brain.head.profile", title: "Core ML", description: "Machine learning for obstacle classification")
                        TechRow(icon: "location", title: "Core Location", description: "Precise GPS and location services")
                        TechRow(icon: "camera", title: "Vision Framework", description: "Advanced image processing and analysis")
                        TechRow(icon: "bluetooth", title: "Bluetooth LE", description: "Low-energy device connectivity")
                    }
                }
                
                // Development Team
=======
                        // MARK: - Core ML Technology
                        TechRow(
                            icon: "brain.head.profile",
                            title: "Core ML",
                            description: "Machine learning for obstacle classification"
                        )
                        
                        // MARK: - Core Location Technology
                        TechRow(
                            icon: "location",
                            title: "Core Location",
                            description: "Precise GPS and location services"
                        )
                        
                        // MARK: - Vision Framework Technology
                        TechRow(
                            icon: "camera",
                            title: "Vision Framework",
                            description: "Advanced image processing and analysis"
                        )
                        
                        // MARK: - Bluetooth LE Technology
                        TechRow(
                            icon: "bluetooth",
                            title: "Bluetooth LE",
                            description: "Low-energy device connectivity"
                        )
                    }
                }
                
                // MARK: - Development Team Section
                // Shows the people behind the app
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("Development Team")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
<<<<<<< HEAD
=======
                        // MARK: - Team Members
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                        TeamMemberRow(name: "Haya Alfakieh", role: "Lead Developer")
                        TeamMemberRow(name: "Thuhieu", role: "UI/UX Designer")
                        TeamMemberRow(name: "SmartCane Team", role: "Research & Development")
                    }
                }
                
<<<<<<< HEAD
                // Contact Information
=======
                // MARK: - Contact Information Section
                // Provides ways for users to get support
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact & Support")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
<<<<<<< HEAD
=======
                        // MARK: - Contact Methods
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                        ContactRow(icon: "envelope", title: "Email", value: "support@smartcane.com")
                        ContactRow(icon: "globe", title: "Website", value: "www.smartcane.com")
                        ContactRow(icon: "phone", title: "Support", value: "+1 (555) 123-4567")
                    }
                }
                
<<<<<<< HEAD
                // Legal
=======
                // MARK: - Legal Information Section
                // Important legal and copyright information
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                VStack(alignment: .leading, spacing: 12) {
                    Text("Legal Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
<<<<<<< HEAD
=======
                        // MARK: - Legal Details
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                        LegalRow(title: "Copyright", value: "© 2024 SmartCane Inc.")
                        LegalRow(title: "License", value: "Proprietary Software")
                        LegalRow(title: "Patents", value: "Multiple patents pending")
                    }
                }
                
<<<<<<< HEAD
                // App Store Links
                VStack(spacing: 12) {
                    Button("Rate on App Store") {
                        // In a real app, this would open the App Store
=======
                // MARK: - App Store Actions Section
                // Buttons for app store interactions
                VStack(spacing: 12) {
                    // MARK: - Rate App Button
                    Button("Rate on App Store") {
                        // In a real app, this would open the App Store rating page
                        // For now, it's just a placeholder
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
<<<<<<< HEAD
                    Button("Share SmartCane") {
                        // In a real app, this would open share sheet
=======
                    // MARK: - Share App Button
                    Button("Share SmartCane") {
                        // In a real app, this would open share sheet
                        // For now, it's just a placeholder
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
<<<<<<< HEAD
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
=======
        .navigationTitle("About")  // Navigation bar title
        .navigationBarTitleDisplayMode(.inline)  // Inline title style
    }
}

// MARK: - Supporting View Components

// MARK: - Feature Row Component
// Displays a single feature with icon, title, and description
struct FeatureRow: View {
    let icon: String      // SF Symbol icon name
    let title: String     // Feature title
    let description: String // Feature description
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)  // Display the feature icon
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)    // Fixed width for alignment
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)  // Display the feature title
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)  // Display the feature description
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

<<<<<<< HEAD
struct TechRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
=======
// MARK: - Technology Row Component
// Displays a single technology with icon, title, and description
struct TechRow: View {
    let icon: String      // SF Symbol icon name
    let title: String     // Technology title
    let description: String // Technology description
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)  // Display the technology icon
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)    // Fixed width for alignment
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)  // Display the technology title
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)  // Display the technology description
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

<<<<<<< HEAD
struct TeamMemberRow: View {
    let name: String
    let role: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(role)
=======
// MARK: - Team Member Row Component
// Displays a single team member with name and role
struct TeamMemberRow: View {
    let name: String   // Team member's name
    let role: String   // Team member's role
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle")  // Person icon
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)    // Fixed width for alignment
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)  // Display the team member's name
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(role)  // Display the team member's role
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

<<<<<<< HEAD
struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
=======
// MARK: - Contact Row Component
// Displays a single contact method with icon, title, and value
struct ContactRow: View {
    let icon: String   // SF Symbol icon name
    let title: String  // Contact method title
    let value: String  // Contact information value
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)  // Display the contact icon
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 24)    // Fixed width for alignment
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)  // Display the contact method title
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)  // Display the contact information
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

<<<<<<< HEAD
struct LegalRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
=======
// MARK: - Legal Row Component
// Displays a single legal item with title and value
struct LegalRow: View {
    let title: String  // Legal item title
    let value: String  // Legal item value
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")  // Document icon
                .font(.title3)
                .foregroundColor(.gray)
                .frame(width: 24)    // Fixed width for alignment
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)  // Display the legal item title
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)  // Display the legal item value
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

<<<<<<< HEAD
=======
// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
>>>>>>> 9e07a6b5c5a513893d71c3878bf0047b42f7ae0d
#Preview {
    NavigationView {
        AboutView()
    }
}
