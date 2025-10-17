////
////  LoginView.swift
////  SmartCane
////
////  Created by Haya Alfakieh on 10/9/25.
////
//
//import Foundation
//import SwiftUI
//import Supabase
//
//struct LoginView: View {
//    @State private var email = ""
//    @State private var password = ""
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack {
//            TextField("Email", text: $email)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .autocapitalization(.none)
//
//            SecureField("Password", text: $password)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//
//            Button("Log In") {
//                Task {
//                    await login()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//
//            if let error = errorMessage {
//                Text(error)
//                    .foregroundColor(.red)
//            }
//        }
//        .padding()
//    }
//
//    func login() async {
//        do {
//            let session = try await supabase.auth.signIn(email: email, password: password)
//            print("✅ Logged in: \(session.user.email ?? "")")
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//}
//
//#Preview {
//    LoginView()
//}
