//
//  AppSettings.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    @Published var vibrationFeedback: Bool {
        didSet { saveSettings() }
    }
    @Published var hapticStrength: String {
        didSet { saveSettings() }
    }
    @Published var soundEffects: Bool {
        didSet { saveSettings() }
    }
    @Published var selectedTheme: String {
        didSet { saveSettings() }
    }
    @Published var selectedLanguage: String {
        didSet { saveSettings(); languageDidChange.send() }
    }
    @Published var preventSleep: Bool {
        didSet {
            saveSettings()
            UIApplication.shared.isIdleTimerDisabled = preventSleep
        }
    }

    let languageDidChange = PassthroughSubject<Void, Never>()

    private let defaults = UserDefaults.standard

    init() {
        vibrationFeedback = defaults.object(forKey: "vibrationFeedback") as? Bool ?? true
        hapticStrength = defaults.string(forKey: "hapticStrength") ?? "Medium"
        soundEffects = defaults.object(forKey: "soundEffects") as? Bool ?? true
        selectedTheme = defaults.string(forKey: "selectedTheme") ?? "Light"
        selectedLanguage = defaults.string(forKey: "selectedLanguage") ?? "English"
        preventSleep = defaults.object(forKey: "preventSleep") as? Bool ?? false

        // Validate language
        let validLanguages = ["English", "French", "Spanish"]
        if !validLanguages.contains(selectedLanguage) {
            selectedLanguage = "English"
            defaults.set(selectedLanguage, forKey: "selectedLanguage")
        }

        // If keys were never set, initialize other defaults
        if defaults.object(forKey: "showTips") == nil {
            resetToDefaults()
        }
    }

    private func saveSettings() {
        defaults.set(vibrationFeedback, forKey: "vibrationFeedback")
        defaults.set(hapticStrength, forKey: "hapticStrength")
        defaults.set(soundEffects, forKey: "soundEffects")
        defaults.set(selectedTheme, forKey: "selectedTheme")
        defaults.set(selectedLanguage, forKey: "selectedLanguage")
        defaults.set(preventSleep, forKey: "preventSleep")
    }

    private func resetToDefaults() {
        vibrationFeedback = true
        hapticStrength = "Medium"
        soundEffects = true
        selectedTheme = "Light"
        selectedLanguage = "English"
        preventSleep = false
        saveSettings()
    }

    // Computed bundle for localization
    var bundle: Bundle {
        switch selectedLanguage {
        case "French": return Bundle.main.path(forResource: "fr", ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        case "Spanish": return Bundle.main.path(forResource: "es", ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        default: return .main
        }
    }
}

// Dynamic Theme Colors
extension AppSettings {
    var bgColor: Color {
        selectedTheme == "Dark" ? Color.black : Color(red: 0.957, green: 0.968, blue: 0.980)
    }

    var cardColor: Color {
        selectedTheme == "Dark" ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.white
    }

    var primaryText: Color {
        selectedTheme == "Dark" ? Color.white : Color.black
    }

    var secondaryText: Color {
        selectedTheme == "Dark" ? Color.white.opacity(0.6) : Color.gray
    }

    var primaryButton: Color {
        Color.orange
    }

    var buttonText: Color {
        Color.white
    }

    var destructive: Color {
        selectedTheme == "Dark" ? Color.red.opacity(0.8) : Color.red
    }

    var destructiveButton: Color {
        Color.red
    }

    var shadowColor: Color {
        selectedTheme == "Dark" ? Color.black.opacity(0.8) : Color.black.opacity(0.06)
    }

    var strokeColor: Color {
        selectedTheme == "Dark" ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
}
