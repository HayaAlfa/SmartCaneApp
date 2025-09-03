import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - App Icon and Name Section
                // Displays the app's visual identity and version information
                VStack(spacing: 16) {
                    // MARK: - App Icon
                    // Large app icon using SF Symbols (in a real app, this would be the actual app icon)
                    Image(systemName: "figure.walk.cane")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    // MARK: - App Name
                    // The main app title
                    Text("SmartCane")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // MARK: - App Version
                    // Current version number
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - App Description Section
                // Explains what the app does and its purpose
                VStack(alignment: .leading, spacing: 12) {
                    Text("About SmartCane")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SmartCane is an innovative mobile application designed to assist users with visual impairments and mobility challenges. The app combines advanced AI technology with location services to provide real-time obstacle detection and navigation assistance.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                
                // MARK: - Key Features Section
                // Highlights the main capabilities of the app
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Technology")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Development Team")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // MARK: - Team Members
                        TeamMemberRow(name: "Haya Alfakieh", role: "Lead Developer")
                        TeamMemberRow(name: "Thuhieu", role: "UI/UX Designer")
                        TeamMemberRow(name: "SmartCane Team", role: "Research & Development")
                    }
                }
                
                // MARK: - Contact Information Section
                // Provides ways for users to get support
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact & Support")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // MARK: - Contact Methods
                        ContactRow(icon: "envelope", title: "Email", value: "support@smartcane.com")
                        ContactRow(icon: "globe", title: "Website", value: "www.smartcane.com")
                        ContactRow(icon: "phone", title: "Support", value: "+1 (555) 123-4567")
                    }
                }
                
                // MARK: - Legal Information Section
                // Important legal and copyright information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Legal Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // MARK: - Legal Details
                        LegalRow(title: "Copyright", value: "© 2024 SmartCane Inc.")
                        LegalRow(title: "License", value: "Proprietary Software")
                        LegalRow(title: "Patents", value: "Multiple patents pending")
                    }
                }
                
                // MARK: - App Store Actions Section
                // Buttons for app store interactions
                VStack(spacing: 12) {
                    // MARK: - Rate App Button
                    Button("Rate on App Store") {
                        // In a real app, this would open the App Store rating page
                        // For now, it's just a placeholder
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    // MARK: - Share App Button
                    Button("Share SmartCane") {
                        // In a real app, this would open share sheet
                        // For now, it's just a placeholder
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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    NavigationView {
        AboutView()
    }
}
