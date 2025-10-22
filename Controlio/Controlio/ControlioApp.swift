//
//  ControlioApp.swift
//  Controlio
//
//  Created by Avis Luong on 10/1/25.
//

import SwiftUI
import FirebaseCore

@main
struct ControlioApp: App {
    @State private var isLoggedIn = false
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content (login or home)
                if isLoggedIn {
                    HomeView()
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }

                // Splash screen
                if showSplash {
                    ContentView()
                        .preferredColorScheme(.light)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showSplash)
            .onAppear {
                // Delay before switching from splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showSplash = false
                }
            }
        }
    }
}
