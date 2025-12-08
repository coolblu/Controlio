//
//  ControlioApp.swift
//  Controlio
//
//  Created by Avis Luong on 10/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import UIKit

// AppDelegate for orientation control
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct ControlioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var userManager: UserManager
    @StateObject private var appSettings: AppSettings
    @State private var isLoggedIn = false
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
        _userManager = StateObject(wrappedValue: UserManager.shared)
        _appSettings = StateObject(wrappedValue: AppSettings())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content (login or home)
                if isLoggedIn {
                    HomeView(isLoggedIn: $isLoggedIn)
                        .environmentObject(userManager)
                        .environmentObject(appSettings)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                        .environmentObject(userManager)
                        .environmentObject(appSettings)
                }

                // Splash screen
                if showSplash {
                    ContentView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(appSettings.selectedTheme == "Dark" ? .dark : .light)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showSplash)
            .animation(.easeInOut, value: appSettings.selectedTheme)
            .onAppear {
                // Determine login state
                isLoggedIn = Auth.auth().currentUser != nil
                userManager.fetchUser()

                // Delay before switching from splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showSplash = false
                }
            }
        }
    }
}
