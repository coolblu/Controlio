//
//  ControlioApp.swift
//  Controlio
//
//  Created by Avis Luong on 10/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct ControlioApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var appSettings = AppSettings()
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
                    HomeView(isLoggedIn: $isLoggedIn)
                        .environmentObject(userManager)
                        .environmentObject(appSettings)
                        .onAppear {
                            if let currentUser = Auth.auth().currentUser {
                                appSettings.setUser(currentUser.uid)
                            }
                        }
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                        .environmentObject(userManager)
                        .environmentObject(appSettings)
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
                if let user = Auth.auth().currentUser {
                    isLoggedIn = true
                    appSettings.setUser(user.uid)
                } else {
                    isLoggedIn = false
                }
                userManager.fetchUser()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showSplash = false
                }
            }
        }
    }
}
