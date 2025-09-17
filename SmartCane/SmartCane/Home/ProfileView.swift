import SwiftUI

struct ProfileView: View {
    @State private var showingEditProfile = false
    @State private var showingAbout = false
    @State private var userName = "John Doe"
    @State private var userEmail = "john.doe@example.com"
    @State private var userPhone = "+1 (555) 123-4567"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Simple profile section
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(userEmail)
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
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(
                    userName: $userName,
                    userEmail: $userEmail,
                    userPhone: $userPhone
                )
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
