import SwiftUI

struct PrivacySettingsView: View {
    @State private var locationSharing = true
    @State private var dataCollection = true
    @State private var analyticsEnabled = false
    @State private var crashReporting = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Location Sharing", isOn: $locationSharing)
                Toggle("Data Collection", isOn: $dataCollection)
                Toggle("Analytics", isOn: $analyticsEnabled)
                Toggle("Crash Reporting", isOn: $crashReporting)
            } footer: {
                Text("These settings help improve the SmartCane app and provide better assistance")
            }
            
            Section {
                NavigationLink("Data Usage") {
                    DataUsageView()
                }
                
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                
                NavigationLink("Terms of Service") {
                    TermsOfServiceView()
                }
            } header: {
                Text("Data & Privacy")
            }
            
            Section {
                NavigationLink("Location Services") {
                    LocationPermissionsView()
                }
                
                NavigationLink("Camera Access") {
                    CameraPermissionsView()
                }
                
                NavigationLink("Bluetooth") {
                    BluetoothPermissionsView()
                }
            } header: {
                Text("Permissions")
            }
            
            Section {
                Button("Export My Data") {
                    exportData()
                }
                .foregroundColor(.blue)
                
                Button("Delete My Data") {
                    deleteData()
                }
                .foregroundColor(.red)
            } header: {
                Text("Data Management")
            } footer: {
                Text("You can export or delete your data at any time")
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportData() {
        // In a real app, this would export user data
        print("Exporting user data...")
    }
    
    private func deleteData() {
        // In a real app, this would delete user data
        print("Deleting user data...")
    }
}

struct DataUsageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Usage Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("The SmartCane app collects and uses data to provide you with the best possible assistance experience.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 12) {
                    DataUsageItem(
                        title: "Location Data",
                        description: "Used for navigation, obstacle detection, and emergency services",
                        isRequired: true
                    )
                    
                    DataUsageItem(
                        title: "Camera Data",
                        description: "Used for obstacle detection and object classification",
                        isRequired: true
                    )
                    
                    DataUsageItem(
                        title: "Usage Analytics",
                        description: "Used to improve app performance and user experience",
                        isRequired: false
                    )
                    
                    DataUsageItem(
                        title: "Device Information",
                        description: "Used for connectivity and troubleshooting",
                        isRequired: true
                    )
                }
                
                Text("All data is encrypted and stored securely. You can control what data is collected in the settings above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsageItem: View {
    let title: String
    let description: String
    let isRequired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(isRequired ? "Required" : "Optional")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isRequired ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(isRequired ? .red : .gray)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use the SmartCane app.")
                    .font(.body)
                
                Group {
                    Text("Information We Collect")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.")
                    
                    Text("How We Use Your Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to ensure your safety.")
                    
                    Text("Data Security")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("By using the SmartCane app, you agree to these terms and conditions.")
                    .font(.body)
                
                Group {
                    Text("Acceptance of Terms")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("By downloading, installing, or using the SmartCane app, you agree to be bound by these Terms of Service.")
                    
                    Text("Use of the App")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("The SmartCane app is designed to assist users with navigation and obstacle detection. It is not a substitute for professional medical advice or assistance.")
                    
                    Text("Limitation of Liability")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("SmartCane is not liable for any damages or injuries that may occur while using the app or device.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LocationPermissionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Location Services")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Location access is required for navigation and obstacle detection features.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Location Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CameraPermissionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Camera Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Camera access is required for obstacle detection and object classification.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Camera Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BluetoothPermissionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bluetooth")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Bluetooth Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Bluetooth access is required to connect to your SmartCane device.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Bluetooth Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PrivacySettingsView()
    }
}
