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
                Task {
                    await loadProfile()
                }
            }
        }
    }
    
    // MARK: - Load profile from Supabase
    private func loadProfile() async {
        guard let user = supabase.auth.currentUser else { return }
        
        do {
            // Try to fetch profile from Supabase
            let profile: [ProfileRow] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .execute()
                .value
            
            if let profileData = profile.first {
                // Load from Supabase
                tempUsername = profileData.username
                tempPhone = profileData.phone
                
                // Also update UserDefaults as local cache
                UserDefaults.standard.set(profileData.username, forKey: "username")
                UserDefaults.standard.set(profileData.phone, forKey: "phone")
            } else {
                // Fallback to UserDefaults if no profile exists in Supabase
                tempUsername = UserDefaults.standard.string(forKey: "username") ?? ""
                tempPhone = UserDefaults.standard.string(forKey: "phone") ?? ""
            }
        } catch {
            print("⚠️ Failed to load profile from Supabase: \(error.localizedDescription)")
            // Fallback to UserDefaults
            tempUsername = UserDefaults.standard.string(forKey: "username") ?? ""
            tempPhone = UserDefaults.standard.string(forKey: "phone") ?? ""
        }
        
        // Email comes from auth user
        if let user = supabase.auth.currentUser {
            tempEmail = user.email ?? ""
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

struct ProfileRow: Decodable {
    let id: UUID
    let username: String
    let phone: String
}
