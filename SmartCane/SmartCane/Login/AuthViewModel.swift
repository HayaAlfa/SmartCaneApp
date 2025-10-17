//
//  AuthViewModel.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/10/25.
//

import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let client = supabase

    func signUp() async {
        errorMessage = nil
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email is required to sign up."
            return
        }
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password is required."
            return
        }

        do {
            let response = try await client.auth.signUp(email: trimmedEmail, password: trimmedPassword)
            
            try? await client.auth.update(user: UserAttributes(data: ["display_name": AnyJSON(trimmedUsername)]))

          

            if !trimmedUsername.isEmpty {
                UserDefaults.standard.set(trimmedEmail, forKey: "email_for_login_\(trimmedUsername)")
                UserDefaults.standard.set(trimmedUsername, forKey: "username")

            }
            if response.session != nil {
                await refreshSessionState()
                errorMessage = nil
            } else {
                isAuthenticated = false
                errorMessage = "Check your email inbox to confirm the account before signing in."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        errorMessage = nil
        let rawUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password is required."
            return
        }

        let resolvedEmail: String?
        if rawUsername.contains("@") {
            resolvedEmail = rawUsername.lowercased()
            
        } else if !rawUsername.isEmpty,
                  let storedEmail = UserDefaults.standard.string(forKey: "email_for_login_\(rawUsername)") {
            resolvedEmail = storedEmail
            
        } else if !trimmedEmail.isEmpty {
            resolvedEmail = trimmedEmail.lowercased()
            
        } else {
            resolvedEmail = nil
        }

        guard let emailToUse = resolvedEmail else {
            errorMessage = "Enter a username or email to sign in."
            return
        }

        do {
            let session = try await client.auth.signIn(email: emailToUse, password: trimmedPassword)
            if session.user != nil {
                if !rawUsername.isEmpty {
                    UserDefaults.standard.set(emailToUse, forKey: "email_for_login_\(rawUsername)")
                    UserDefaults.standard.set(rawUsername, forKey: "username")
                }
                await refreshSessionState()
                errorMessage = nil
                if username.isEmpty {
                    username = rawUsername
                }
            } else {
                isAuthenticated = false
                errorMessage = "Unable to start session. Please verify your credentials."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        let cachedUsername = username
        do {
            try await client.auth.signOut()
            print("Current session:", try? await client.auth.session)

            // ✅ Clear local state
            isAuthenticated = false
            username = ""
            email = ""
            password = ""
            errorMessage = nil

            // ✅ Remove cached user info
            UserDefaults.standard.removeObject(forKey: "username")
            if !cachedUsername.isEmpty {
                UserDefaults.standard.removeObject(forKey: "email_for_login_\(cachedUsername)")
            }

            print("👋 Successfully signed out.")
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Sign-out failed:", error.localizedDescription)
        }
    }

    private func refreshSessionState() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = session.user != nil

            if isAuthenticated {
                if username.isEmpty {
                    username = UserDefaults.standard.string(forKey: "username") ?? ""
                }
                if email.isEmpty {
                    email = session.user.email ?? email
                }
            }
        } catch {
            isAuthenticated = client.auth.currentUser != nil
        }
    }
    func restoreSession() async {
        do {
            // Try to load the current session from storage
            let session = try await client.auth.session
            if session.user != nil {
                isAuthenticated = true
                username = UserDefaults.standard.string(forKey: "username") ?? ""
                email = session.user.email ?? ""
                print("✅ Session restored for:", email)
            } else {
                isAuthenticated = false
                print("❌ No active session found.")
            }
        } catch {
            // If the session is invalid (expired, revoked, etc.)
            isAuthenticated = false
            print("⚠️ Failed to restore session:", error.localizedDescription)
        }
    }


}
