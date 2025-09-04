import SwiftUI

struct EditProfileView: View {
    // MARK: - Properties
    @StateObject private var dataManager = TempDataManager.shared
    
    // MARK: - Environment
    // @Environment provides access to the current view's environment
    @Environment(\.dismiss) private var dismiss  // Used to close the sheet
    
    // MARK: - State Properties
    // @State properties are used for temporary data while editing
    // These are separate from the binding properties to allow for "Cancel" functionality
    @State private var tempUserName: String = ""    // Temporary copy of user name
    @State private var tempUserEmail: String = ""   // Temporary copy of user email
    @State private var tempUserPhone: String = ""   // Temporary copy of user phone
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Personal Information Section
                // Main form section for user details
                Section("Personal Information") {
                    // MARK: - Name Input Field
                    // Text field for editing user's full name
                    TextField("Full Name", text: $tempUserName)
                        .textContentType(.name)  // iOS will suggest names from contacts
                    
                    // MARK: - Email Input Field
                    // Text field for editing user's email address
                    TextField("Email", text: $tempUserEmail)
                        .textContentType(.emailAddress)  // iOS will suggest emails
                        .keyboardType(.emailAddress)     // Show email keyboard
                        .autocapitalization(.none)       // Don't auto-capitalize emails
                    
                    // MARK: - Phone Input Field
                    // Text field for editing user's phone number
                    TextField("Phone Number", text: $tempUserPhone)
                        .textContentType(.telephoneNumber)  // iOS will suggest phone numbers
                        .keyboardType(.phonePad)            // Show phone number keyboard
                }
                
                // MARK: - Profile Picture Section
                // Section for managing profile picture (currently just a placeholder)
                Section("Profile Picture") {
                    HStack {
                        // MARK: - Current Profile Picture
                        // Display the current profile picture (using SF Symbols for now)
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        // MARK: - Profile Picture Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Picture")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // MARK: - Change Picture Button
                        // Button to change profile picture (placeholder functionality)
                        Button("Change") {
                            // In a real app, this would open photo picker
                            // For now, it's just a placeholder
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Profile")  // Navigation bar title
            .navigationBarTitleDisplayMode(.inline)  // Inline title style
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // MARK: - Cancel Button
                    // Button to discard changes and return to original values
                    Button("Cancel") {
                        dismiss()  // Close the sheet without saving
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Save Button
                    // Button to apply changes and update the parent view
                    Button("Save") {
                        saveChanges()  // Call the save function
                    }
                    .disabled(tempUserName.isEmpty || tempUserEmail.isEmpty)  // Disable if required fields are empty
                }
            }
            .onAppear {
                // MARK: - View Setup
                // This runs when the view appears on screen
                // Copy the current values to temporary variables
                tempUserName = dataManager.userAccount.name
                tempUserEmail = dataManager.userAccount.email
                tempUserPhone = dataManager.userAccount.phone
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Save Changes Function
    // Updates the temporary data manager with the edited values
    private func saveChanges() {
        // Update the temporary data manager user account
        dataManager.userAccount.name = tempUserName
        dataManager.userAccount.email = tempUserEmail
        dataManager.userAccount.phone = tempUserPhone
        dataManager.saveData()
        
        // Close the sheet
        dismiss()
    }
}

// MARK: - Preview
// Shows the view in Xcode's canvas for design purposes
// We use .constant() to create binding values for the preview
#Preview {
    EditProfileView()
}
