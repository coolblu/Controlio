//
//  AuthView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

//
//  AuthView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import AuthenticationServices

struct AuthView: View {
    let isSignUp: Bool
    let onSwitch: () -> Void
    let onAuthSuccess: () -> Void

    // State variables
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, password, confirmPassword }

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            Image("controlio_logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            Text(isSignUp ? "Create Account" : "Welcome to Controlio")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            // Input Fields
            VStack(spacing: 12) {
                StyledTextField(placeholder: "Email", text: $email, isFocused: focusedField == .email)
                    .focused($focusedField, equals: .email)

                SecureToggleField(placeholder: "Password", text: $password, show: $showPassword, isFocused: focusedField == .password)
                    .focused($focusedField, equals: .password)

                if isSignUp {
                    SecureToggleField(placeholder: "Confirm Password", text: $confirmPassword, show: $showConfirmPassword, isFocused: focusedField == .confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                }
            }
            // Error message
            if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Primary button
            StyledButton(title: isSignUp ? "Create Account" : "Login", color: .orange, textColor: .white, iconName: nil) {
                handleAuth()
            }
            
            // Switch screen
            Button(action: onSwitch) {
               Text(isSignUp ? "Already have an account? " : "Don’t have an account? ")
                   .foregroundColor(.gray)
               + Text(isSignUp ? "Log in" : "Sign up")
                   .foregroundColor(.orange)
           }
           .font(.footnote)
            
            // Separator for alternative sign in options
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.4))
                Text("or continue with")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.4))
            }
            
            // Google Sign-In
            StyledButton(title: "Sign in with Google", color: .white, textColor: .black, iconName: "google_icon") {
                handleGoogleSignIn()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // Firebase Auth
    private func handleAuth() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        if isSignUp {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }

            AuthManager.shared.signUp(email: email, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success: onAuthSuccess()
                    case .failure(let error): errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            AuthManager.shared.login(email: email, password: password) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success: onAuthSuccess()
                    case .failure(let error): errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // Get view controller for google auth screen
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootVC
    }
    
    // Google Auth
    private func handleGoogleSignIn() {
        guard let rootVC = getRootViewController() else { return }
        AuthManager.shared.googleSignIn(presenting: rootVC) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: onAuthSuccess()
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Previews
#Preview {
    VStack(spacing: 40) {
        AuthView(isSignUp: false, onSwitch: {}, onAuthSuccess: {})
        Divider()
        AuthView(isSignUp: true, onSwitch: {}, onAuthSuccess: {})
    }
    .padding()
}
