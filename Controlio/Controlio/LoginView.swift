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
    @EnvironmentObject var appSettings: AppSettings

    private let topSpacing: CGFloat = 44

    var body: some View {
        ZStack {
            appSettings.bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: topSpacing)

                // Auth screens
                ZStack {
                    // Login screen
                    if !showSignUp {
                        AuthView(
                            isSignUp: false,
                            onSwitch: { showSignUp = true },
                            onAuthSuccess: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isLoggedIn = true
                                }
                            }
                        )
                        .transition(.move(edge: .leading))
                    }
                    
                    // Sign up screen
                    if showSignUp {
                        AuthView(
                            isSignUp: true,
                            onSwitch: { showSignUp = false },
                            onAuthSuccess: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isLoggedIn = true
                                }
                            }
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
