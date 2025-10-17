import SwiftUI
import Supabase

struct EditProfileView: View {
    // MARK: - Observed ViewModel
    @StateObject private var authVM = AuthViewModel()
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State for temporary editing
    @State private var tempUsername: String = ""
    @State private var tempEmail: String = ""
    @State private var tempPhone: String = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Username", text: $tempUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Email", text: $tempEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(true) // email can't be edited
                    
                    TextField("Phone Number", text: $tempPhone)
                        .keyboardType(.phonePad)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Section("Profile Picture") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Picture")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Change") {
                            // Add photo picker here
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveProfile() }
                    }
                    .disabled(tempUsername.isEmpty || isSaving)
                }
            }
            .onAppear {
                // Load current credentials from Supabase
                if let user = supabase.auth.currentUser {
                    tempEmail = user.email ?? ""
                    tempUsername = UserDefaults.standard.string(forKey: "username") ?? ""
                    tempPhone = UserDefaults.standard.string(forKey: "phone") ?? ""
                }
            }
        }
    }
    
    // MARK: - Save profile to Supabase / local storage
    private func saveProfile() async {
        guard let user = supabase.auth.currentUser else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Save username locally for now
            UserDefaults.standard.set(tempUsername, forKey: "username")
            UserDefaults.standard.set(tempPhone, forKey: "phone")
            
            // Optionally update a Supabase table like "profiles" for extra fields
            let updateData = ProfileUpdate(username: tempUsername, phone: tempPhone)
            try await supabase
                .from("profiles")
                .update(updateData) // ✅ Works
                .eq("id", value: user.id)
                .execute()
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
struct ProfileUpdate: Encodable {
    let username: String
    let phone: String
}
