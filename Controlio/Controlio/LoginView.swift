//
//  LoginView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI

/// Wrapper handling login/signup switching
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var showSignUp = false

    private let backgroundColor = Color(red: 0.957, green: 0.968, blue: 0.980)
    private let topSpacing: CGFloat = 44

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: topSpacing)

                // Auth screens
                ZStack {
                    if !showSignUp {
                        AuthView(
                            isSignUp: false,
                            onSwitch: { showSignUp = true },
                            onAuthSuccess: { isLoggedIn = true }
                        )
                        .transition(.move(edge: .leading))
                    }

                    if showSignUp {
                        AuthView(
                            isSignUp: true,
                            onSwitch: { showSignUp = false },
                            onAuthSuccess: { isLoggedIn = true }
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
#Preview {
    LoginView(isLoggedIn: .constant(false))
}
