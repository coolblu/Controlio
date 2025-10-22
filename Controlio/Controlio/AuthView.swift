//
//  AuthView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI
import FirebaseCore

/// Main authentication view layout for login or signup
struct AuthView: View {
    let isSignUp: Bool              // Determines if signup or login screen
    let onSwitch: () -> Void        // Action to switch screens
    let onAuthSuccess: () -> Void   // Action after successful login/signup

    // State variables
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    // Shared focus state for all fields
    @FocusState private var focusedField: Field?

    /// Enum to track which field is focused
    enum Field: Hashable {
        case username
        case password
        case confirmPassword
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // Background color and global tap area to dismiss focus
                Color(red: 0.957, green: 0.968, blue: 0.980)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }

                VStack(spacing: h * 0.02) {
                    Spacer().frame(height: h * 0.02)

                    // Logo and Title
                    Image("controlio_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.6)
                        .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 8)

                    Text(isSignUp ? "Create Your Account" : "Welcome to Controlio")
                        .font(.custom("SF Pro", size: geo.size.width * 0.06))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)

                    Spacer().frame(height: h * 0.001)

                    VStack(spacing: h * 0.02) {
                        // Authentication fields with shared focus
                        StyledTextField(
                            placeholder: "Username",
                            text: $username,
                            isFocused: focusedField == .username
                        )
                        .focused($focusedField, equals: .username)

                        SecureToggleField(
                            placeholder: "Password",
                            text: $password,
                            show: $showPassword,
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)

                        if isSignUp {
                            SecureToggleField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                show: $showConfirmPassword,
                                isFocused: focusedField == .confirmPassword
                            )
                            .focused($focusedField, equals: .confirmPassword)
                        }

                        // Error message only shows when there is one
                        Text(errorMessage ?? " ")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 5)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(errorMessage == nil ? 0 : 1)

                        // Login / Create Account button
                        StyledButton(
                            title: isSignUp ? "Create Account" : "Login",
                            color: Color(red: 0.25, green: 0.25, blue: 0.25)
                        ) {
                            handleAuth()
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.7 : 1)

                        // Sign up button for login screen
                        if !isSignUp {
                            StyledButton(title: "Sign up", color: .orange, action: onSwitch)
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(nil, value: errorMessage)

                    Spacer()
                }
            }
        }
    }

    /// Handles login or signup using AuthManager
    private func handleAuth() {
        errorMessage = nil
        isLoading = true

        if isSignUp {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                isLoading = false
                return
            }

            AuthManager.shared.signUp(email: username, password: password) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        onAuthSuccess()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            AuthManager.shared.login(email: username, password: password) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        onAuthSuccess()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

/// Standard text field with consistent styling
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
            }

            TextField("", text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.none)
                .padding(.leading, 12)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(isFocused ? 0.35 : 0.25), radius: 4, y: 4)
    }
}

/// Password field with show/hide toggle
struct SecureToggleField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool
    let isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
            }

            HStack {
                if show {
                    TextField("", text: $text)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.none)
                        .padding(.trailing, 36)
                } else {
                    SecureField("", text: $text)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.none)
                        .padding(.trailing, 36)
                }

                Button(action: { show.toggle() }) {
                    Image(systemName: show ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
            .padding(.leading, 12)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(isFocused ? 0.35 : 0.25), radius: 4, y: 4)
    }
}

/// Custom button style for natural tap animation
struct PressableButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Authentication button with styling
struct StyledButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PressableButtonStyle(color: color))
    }
}

// Previews
#Preview("Login") {
    AuthView(isSignUp: false, onSwitch: {}, onAuthSuccess: {})
}

#Preview("Sign Up") {
    AuthView(isSignUp: true, onSwitch: {}, onAuthSuccess: {})
}
