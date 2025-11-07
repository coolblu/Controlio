//
//  AppSettings.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

final class AppSettings: ObservableObject {
    @Published var showTips: Bool = true {
        didSet { saveSettings() }
    }
    @Published var connectionAlerts: Bool = true {
        didSet { saveSettings() }
    }
    @Published var updateReminders: Bool = true {
        didSet { saveSettings() }
    }
    @Published var selectedTheme: String = "Light" {
        didSet { saveSettings() }
    }
    @Published var selectedLanguage: String = "System Default" {
        didSet { saveSettings() }
    }

    private var db = Firestore.firestore()
    private var userId: String?

    init() {
        // If user is already logged in, set userId and load settings
        if let user = Auth.auth().currentUser {
            setUser(user.uid)
        }
    }

    /// Call this after user logs in
    func setUser(_ uid: String) {
        userId = uid
        loadSettings()
    }

    /// Reset to default values
    private func resetToDefaults() {
        showTips = true
        connectionAlerts = true
        updateReminders = true
        selectedTheme = "Light"
        selectedLanguage = "System Default"
    }

    /// Load settings from Firestore or create defaults if missing
    private func loadSettings() {
        guard let uid = userId else { return }

        let docRef = db.collection("users").document(uid)
                        .collection("settings").document("preferences")

        docRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let data = snapshot?.data(), error == nil {
                // Document exists — load data
                DispatchQueue.main.async {
                    self.showTips = data["showTips"] as? Bool ?? true
                    self.connectionAlerts = data["connectionAlerts"] as? Bool ?? true
                    self.updateReminders = data["updateReminders"] as? Bool ?? true
                    self.selectedTheme = data["selectedTheme"] as? String ?? "Light"
                    self.selectedLanguage = data["selectedLanguage"] as? String ?? "System Default"
                }
            } else {
                // Document missing — initialize defaults and save
                DispatchQueue.main.async {
                    self.resetToDefaults()
                    self.saveSettings()
                }
            }
        }
    }

    /// Save current settings to Firestore
    private func saveSettings() {
        guard let uid = userId else { return }

        let data: [String: Any] = [
            "showTips": showTips,
            "connectionAlerts": connectionAlerts,
            "updateReminders": updateReminders,
            "selectedTheme": selectedTheme,
            "selectedLanguage": selectedLanguage
        ]

        db.collection("users").document(uid)
          .collection("settings").document("preferences")
          .setData(data, merge: true)
    }
}
