import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - App Icon and Name Section
                VStack(spacing: 16) {
                    Image(systemName: "figure.walk.cane")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("SmartCane")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // MARK: - App Description Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About SmartCane")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("SmartCane is an innovative mobile application designed to assist users with visual impairments and mobility challenges. The app combines advanced AI technology with location services to provide real-time obstacle detection and navigation assistance.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }

                // MARK: - Key Features Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Features")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "map",
                                   title: "Real-time Navigation",
                                   description: "GPS-based location tracking and route guidance")

                        FeatureRow(icon: "camera.viewfinder",
                                   title: "Obstacle Detection",
                                   description: "AI-powered object recognition and classification")

                        FeatureRow(icon: "mappin.and.ellipse",
                                   title: "Saved Locations",
                                   description: "Store and manage frequently visited places")

                        FeatureRow(icon: "bell",
                                   title: "Smart Alerts",
                                   description: "Customizable notifications for safety and convenience")
                    }
                }

                // MARK: - Technology Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Technology")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        TechRow(icon: "brain.head.profile",
                                title: "Core ML",
                                description: "Machine learning for obstacle classification")

                        TechRow(icon: "location",
                                title: "Core Location",
                                description: "Precise GPS and location services")

                        TechRow(icon: "camera",
                                title: "Vision Framework",
                                description: "Advanced image processing and analysis")

                        TechRow(icon: "bluetooth",
                                title: "Bluetooth LE",
                                description: "Low-energy device connectivity")
                    }
                }

                // MARK: - Development Team Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Development Team")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        TeamMemberRow(name: "Haya Alfakieh", role: "Lead Developer")
                        TeamMemberRow(name: "Thuhieu", role: "UI/UX Designer")
                        TeamMemberRow(name: "SmartCane Team", role: "Research & Development")
                    }
                }

                // MARK: - Contact Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact & Support")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        ContactRow(icon: "envelope", title: "Email", value: "support@smartcane.com")
                        ContactRow(icon: "globe", title: "Website", value: "www.smartcane.com")
                        ContactRow(icon: "phone", title: "Support", value: "+1 (555) 123-4567")
                    }
                }

                // MARK: - Legal Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Legal Information")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        LegalRow(title: "Copyright", value: "© 2024 SmartCane Inc.")
                        LegalRow(title: "License", value: "Proprietary Software")
                        LegalRow(title: "Patents", value: "Multiple patents pending")
                    }
                }

                // MARK: - App Store Actions Section
                VStack(spacing: 12) {
                    Button("Rate on App Store") {
                        // Open App Store rating page
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Share SmartCane") {
                        // Open share sheet
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
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting View Components

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AboutView()
    }
}

