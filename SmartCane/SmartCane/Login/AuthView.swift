//
//  AuthView.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 10/10/25.
//

import SwiftUI
import Foundation


struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isLoginMode = true

    var body: some View {
        VStack(spacing: 24) {
            Text(isLoginMode ? "Welcome Back" : "Create Account")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                if !isLoginMode {
                    // Signup mode: email + username + password
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                } else {
                    // Login mode: username only
                    TextField("Email", text: $viewModel.username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }

                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button {
                Task {
                    if isLoginMode {
                        await viewModel.signIn()
                    } else {
                        await viewModel.signUp()
                    }
                }
            } label: {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(isLoginMode ? "Don’t have an account? Sign Up" : "Already have an account? Login") {
                withAnimation {
                    isLoginMode.toggle()
                }
            }
            .font(.footnote)
            .foregroundColor(.blue)

            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {

            MainTabView(isAuthenticated: $viewModel.isAuthenticated) {
                await viewModel.signOut()
            }
        }
    }
}
