import SwiftUI
import Supabase

struct ProfileView: View {
    @State private var showingEditProfile = false
    @State private var showingAbout = false
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var userPhone = "+1 (555) 123-4567"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Simple profile section
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(userName.isEmpty ? "Username" : userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(userEmail.isEmpty ? "Email" : userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Simple info section
                VStack(spacing: 15) {
                    HStack {
                        Text("Phone:")
                        Spacer()
                        Text(userPhone)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Member Since:")
                        Spacer()
                        Text("Jan 2024")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Simple buttons
                VStack(spacing: 15) {
                    Button("Edit Profile") {
                        showingEditProfile = true
                    }
                    .buttonStyle(SimpleButtonStyle())
                    
                    Button("About App") {
                        showingAbout = true
                    }
                    .buttonStyle(SimpleButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await loadCurrentUser()
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView ()
                    
                    
                    
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    // MARK: - Load current user credentials from Supabase
    private func loadCurrentUser() async {
        guard let user = supabase.auth.currentUser else { return }
        
        // Load email from auth user
        userEmail = user.email ?? ""
        
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
                userName = profileData.username
                userPhone = profileData.phone
                
                // Also update UserDefaults as local cache
                UserDefaults.standard.set(profileData.username, forKey: "username")
                UserDefaults.standard.set(profileData.phone, forKey: "phone")
            } else {
                // Fallback to UserDefaults if no profile exists in Supabase
                userName = UserDefaults.standard.string(forKey: "username") ?? ""
                userPhone = UserDefaults.standard.string(forKey: "phone") ?? "+1 (555) 123-4567"
            }
        } catch {
            print("⚠️ Failed to load profile from Supabase: \(error.localizedDescription)")
            // Fallback to UserDefaults
            userName = UserDefaults.standard.string(forKey: "username") ?? ""
            userPhone = UserDefaults.standard.string(forKey: "phone") ?? "+1 (555) 123-4567"
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
