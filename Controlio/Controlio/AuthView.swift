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
    @EnvironmentObject var appSettings: AppSettings

    enum Field: Hashable { case email, password, confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo
                Image("controlio_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .shadow(color: appSettings.shadowColor, radius: 8, y: 4)

                // Title
                Text(
                    NSLocalizedString(
                        isSignUp ? "Create Account" : "Welcome to Controlio",
                        bundle: appSettings.bundle,
                        comment: ""
                    )
                )
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(appSettings.primaryText)

                // Input Fields
                VStack(spacing: 12) {
                    StyledTextField(
                        placeholder: NSLocalizedString("Email", bundle: appSettings.bundle, comment: ""),
                        text: $email,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .environmentObject(appSettings)

                    SecureToggleField(
                        placeholder: NSLocalizedString("Password", bundle: appSettings.bundle, comment: ""),
                        text: $password,
                        show: $showPassword,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .environmentObject(appSettings)

                    if isSignUp {
                        SecureToggleField(
                            placeholder: NSLocalizedString("Confirm Password", bundle: appSettings.bundle, comment: ""),
                            text: $confirmPassword,
                            show: $showConfirmPassword,
                            isFocused: focusedField == .confirmPassword
                        )
                        .focused($focusedField, equals: .confirmPassword)
                        .environmentObject(appSettings)
                    }
                }

                // Error message
                if let message = errorMessage {
                    Text(message)
                        .foregroundColor(appSettings.destructive)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Primary button
                StyledButton(
                    title: NSLocalizedString(isSignUp ? "Create Account" : "Login", bundle: appSettings.bundle, comment: ""),
                    backgroundColor: appSettings.primaryButton,
                    textColor: appSettings.buttonText,
                    iconName: nil
                ) {
                    handleAuth()
                }

                // Switch screen
                Button(action: onSwitch) {
                    Text(
                        NSLocalizedString(
                            isSignUp ? "Already have an account? " : "Don’t have an account? ",
                            bundle: appSettings.bundle,
                            comment: ""
                        )
                    )
                    .foregroundColor(appSettings.secondaryText)
                    + Text(
                        NSLocalizedString(
                            isSignUp ? "Log in" : "Sign up",
                            bundle: appSettings.bundle,
                            comment: ""
                        )
                    )
                    .foregroundColor(appSettings.primaryButton)
                }
                .font(.footnote)

                // Separator for alternative sign in options
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(appSettings.strokeColor)
                    Text(
                        NSLocalizedString("or continue with", bundle: appSettings.bundle, comment: "")
                    )
                    .font(.footnote)
                    .foregroundColor(appSettings.secondaryText)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(appSettings.strokeColor)
                }

                // Google Sign-In
                StyledButton(
                    title: NSLocalizedString("Sign in with Google", bundle: appSettings.bundle, comment: ""),
                    backgroundColor: appSettings.cardColor,
                    textColor: appSettings.primaryText,
                    iconName: "google_icon"
                ) {
                    handleGoogleSignIn()
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(appSettings.bgColor.ignoresSafeArea())
    }

    // Firebase Auth
    private func handleAuth() {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = NSLocalizedString("Please fill in all fields.", bundle: appSettings.bundle, comment: "")
            return
        }

        if isSignUp {
            guard password == confirmPassword else {
                errorMessage = NSLocalizedString("Passwords do not match.", bundle: appSettings.bundle, comment: "")
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

// Preview
#Preview {
    AuthView(isSignUp: false, onSwitch: {}, onAuthSuccess: {})
        .environmentObject(AppSettings())
}
