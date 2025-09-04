import SwiftUI
import UserNotifications  // For checking and requesting notification permissions

struct ProfileView: View {
    // MARK: - State Properties
    // These properties control the UI state and store user preferences
    @StateObject private var dataManager = TempDataManager.shared  // Temporary data manager
    @State private var notificationsEnabled = false      // Whether notifications are allowed
    @State private var locationServicesEnabled = false   // Whether location services are active
    @State private var bluetoothEnabled = false          // Whether bluetooth is connected
    @State private var showingEditProfile = false        // Controls edit profile sheet
    @State private var showingNotificationSettings = false // Controls notification settings sheet
    @State private var showingPrivacySettings = false    // Controls privacy settings sheet
    @State private var showingAbout = false              // Controls about app sheet
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Profile Header Section
                    // Shows user's profile picture and basic information
                    profileHeaderSection
                    
                    // MARK: - Account Information Section
                    // Displays user's account details like email and phone
                    accountInformationSection
                    
                    // MARK: - Settings Section
                    // Shows various app settings and permissions
                    settingsSection
                    
                    // MARK: - Connection Status Section
                    // Shows status of various device connections
                    connectionStatusSection
                    
                    // MARK: - App Information Section
                    // Shows app version and legal information
                    appInformationSection
                }
                .padding()
            }
            .navigationTitle("Profile")  // Navigation bar title
            .navigationBarTitleDisplayMode(.large)  // Large title style
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Edit button in top-right corner
                    Button("Edit") {
                        showingEditProfile = true  // Show edit profile sheet
                    }
                }
            }
            
            // MARK: - Sheet Presentations
            // These sheets present different settings views
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView(notificationsEnabled: $notificationsEnabled)
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .onAppear {
                checkPermissions()  // Check current permission status when view appears
            }
        }
    }
    
    // MARK: - Profile Header Section
    // Displays user's profile picture and basic information
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // MARK: - Profile Picture
            // Large circular profile picture (using SF Symbols for now)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // MARK: - User Info
            VStack(spacing: 8) {
                Text(dataManager.userAccount.name)  // User's display name
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(dataManager.userAccount.email.isEmpty ? "No email" : dataManager.userAccount.email)  // User's email address
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // User type badge
                Text("SmartCane User")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))  // Subtle blue background
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)  // Translucent background
        .cornerRadius(16)
    }
    
    // MARK: - Account Information Section
    // Shows detailed account information in a structured format
    private var accountInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.text.rectangle")  // Person with text icon
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Account Information")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                // Display various account details using custom InfoRow component
                InfoRow(icon: "envelope", title: "Email", value: dataManager.userAccount.email.isEmpty ? "No email" : dataManager.userAccount.email)
                InfoRow(icon: "phone", title: "Phone", value: dataManager.userAccount.phone.isEmpty ? "No phone" : dataManager.userAccount.phone)
                InfoRow(icon: "calendar", title: "Member Since", value: "January 2024")
                InfoRow(icon: "location", title: "Location", value: "San Francisco, CA")
            }
            .padding()
            .background(Color.gray.opacity(0.1))  // Light gray background
            .cornerRadius(12)
        }
    }
    
    // MARK: - Settings Section
    // Shows various app settings and permission controls
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape")  // Gear icon for settings
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                // MARK: - Notification Settings
                SettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    subtitle: notificationsEnabled ? "Enabled" : "Disabled",
                    color: notificationsEnabled ? .green : .gray
                ) {
                    showingNotificationSettings = true  // Show notification settings
                }
                
                // MARK: - Location Services Settings
                SettingsRow(
                    icon: "location",
                    title: "Location Services",
                    subtitle: locationServicesEnabled ? "Enabled" : "Disabled",
                    color: locationServicesEnabled ? .green : .gray
                ) {
                    openLocationSettings()  // Open iOS Settings app
                }
                
                // MARK: - Bluetooth Settings
                SettingsRow(
                    icon: "bluetooth",
                    title: "Bluetooth",
                    subtitle: bluetoothEnabled ? "Connected" : "Disconnected",
                    color: bluetoothEnabled ? .green : .gray
                ) {
                    openBluetoothSettings()  // Open iOS Settings app
                }
                
                // MARK: - Privacy & Security Settings
                SettingsRow(
                    icon: "hand.raised",
                    title: "Privacy & Security",
                    subtitle: "Manage permissions",
                    color: .blue
                ) {
                    showingPrivacySettings = true  // Show privacy settings
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Connection Status Section
    // Shows real-time status of various device connections
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi")  // WiFi icon for connections
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Connection Status")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                // Show status of SmartCane device connection
                ConnectionStatusRow(
                    title: "SmartCane Device",
                    status: "Connected",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // Show GPS signal strength
                ConnectionStatusRow(
                    title: "GPS Signal",
                    status: "Strong",
                    icon: "location.fill",
                    color: .blue
                )
                
                // Show internet connection type
                ConnectionStatusRow(
                    title: "Internet",
                    status: "WiFi",
                    icon: "wifi",
                    color: .green
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - App Information Section
    // Shows app version, legal information, and about section
    private var appInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")  // Info icon
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("App Information")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                // Display app details using InfoRow component
                InfoRow(icon: "app", title: "Version", value: "1.0.0")
                InfoRow(icon: "calendar", title: "Last Updated", value: "December 2024")
                InfoRow(icon: "doc.text", title: "Terms of Service", value: "View")
                InfoRow(icon: "hand.raised", title: "Privacy Policy", value: "View")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Button to show about app information
            Button("About SmartCane") {
                showingAbout = true  // Show about app sheet
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    // Check current permission status for various services
    private func checkPermissions() {
        // Check notification permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {  // Update UI on main thread
                self.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
        
        // Check location permission status (simplified for demo)
        locationServicesEnabled = true // In a real app, check actual permission status
        
        // Check bluetooth status (simplified for demo)
        bluetoothEnabled = false // In a real app, check actual bluetooth status
    }
    
    // Open iOS Settings app to location permissions
    private func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Open iOS Settings app to bluetooth settings
    private func openBluetoothSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Supporting View Components

// Component for displaying information in a row format
struct InfoRow: View {
    let icon: String      // SF Symbol icon name
    let title: String     // Label for the information
    let value: String     // The actual value to display
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)  // Display the icon
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)    // Fixed width for alignment
            
            Text(title)  // Display the title/label
                .font(.subheadline)
            
            Spacer()  // Push value to right side
            
            Text(value)  // Display the value
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Component for settings rows with action buttons
struct SettingsRow: View {
    let icon: String      // SF Symbol icon name
    let title: String     // Setting title
    let subtitle: String  // Setting description or status
    let color: Color      // Color for the icon
    let action: () -> Void // Function to call when tapped
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)  // Display the icon
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)  // Display the setting title
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)  // Display the subtitle/status
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Chevron arrow to indicate tappable
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())  // Remove default button styling
    }
}

// Component for displaying connection status
struct ConnectionStatusRow: View {
    let title: String   // Connection name
    let status: String  // Connection status
    let icon: String    // SF Symbol icon name
    let color: Color    // Color for the status
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)  // Display the icon
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)  // Display the connection name
                .font(.subheadline)
            
            Spacer()
            
            Text(status)  // Display the connection status
                .font(.subheadline)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
#Preview {
    ProfileView()
}
