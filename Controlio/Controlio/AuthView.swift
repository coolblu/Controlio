//
//  AuthView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI

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
    
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            
            ZStack {
                // Background color
                Color(red: 0.957, green: 0.968, blue: 0.980)
                    .ignoresSafeArea()
                
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
                        // Authentication fields
                        StyledTextField(placeholder: "Username", text: $username)
                        SecureToggleField(placeholder: "Password", text: $password, show: $showPassword)
                        
                        if isSignUp {
                            SecureToggleField(placeholder: "Confirm Password", text: $confirmPassword, show: $showConfirmPassword)
                        }
                        
                        // Action buttons
                        StyledButton(title: isSignUp ? "Create Account" : "Login", color: Color(red: 0.25, green: 0.25, blue: 0.25), action: onAuthSuccess)
                        
                        if !isSignUp {
                            StyledButton(title: "Sign up", color: .orange, action: onSwitch)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
    }
}

/// Standard text field with consistent styling
struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    
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
                .padding(.leading, 12)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
    }
}

/// Password field with show/hide toggle
struct SecureToggleField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
            }

            HStack {
                // Switch between SecureField and TextField
                if show {
                    TextField("", text: $text)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.trailing, 36)
                } else {
                    SecureField("", text: $text)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
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
        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
        }
    }
}

// Previews
#Preview("Login") {
    AuthView(isSignUp: false, onSwitch: {}, onAuthSuccess: {})
}

#Preview("Sign Up") {
    AuthView(isSignUp: true, onSwitch: {}, onAuthSuccess: {})
}
