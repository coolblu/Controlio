//
//  LoginView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI

import SwiftUI

/// Creation of login and sign up screens
struct LoginView: View {
    @Binding var isLoggedIn: Bool          // <-- binding to app login state
    @State private var showSignUp: Bool = false
    private let backgroundColor = Color(red: 0.957, green: 0.968, blue: 0.980)
    private let topSpacing: CGFloat = 44

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: topSpacing)
                
                HStack {
                    // Back button for Sign Up
                    Button(action: { showSignUp = false }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                        Text("Back to Login")
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal)
                    .opacity(showSignUp ? 1 : 0)
                    
                    Spacer()
                }

                ZStack {
                    // Login screen
                    if !showSignUp {
                        AuthView(
                            isSignUp: false,
                            onSwitch: { showSignUp.toggle() },
                            onAuthSuccess: { isLoggedIn = true }    // <-- update app login state
                        )
                        .transition(.move(edge: .leading))
                    }
                    
                    // Sign up screen
                    if showSignUp {
                        AuthView(
                            isSignUp: true,
                            onSwitch: { showSignUp.toggle() },
                            onAuthSuccess: { isLoggedIn = true }    // <-- update app login state
                        )
                        .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut, value: showSignUp)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Previews
#Preview("Login") {
    LoginView(isLoggedIn: .constant(false))
}

#Preview("Sign Up") {
    LoginView(isLoggedIn: .constant(false))
}
