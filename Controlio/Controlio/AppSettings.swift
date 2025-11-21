//
//  AppSettings.swift
//  Controlio
//
//  Created by Jerry Lin on 11/7/25.
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    // App Settings
    @Published var vibrationFeedback: Bool {
        didSet { defaults.set(vibrationFeedback, forKey: "vibrationFeedback") }
    }
    @Published var hapticStrength: String {
        didSet { defaults.set(hapticStrength, forKey: "hapticStrength") }
    }
    @Published var soundEffects: Bool {
        didSet { defaults.set(soundEffects, forKey: "soundEffects") }
    }
    @Published var selectedTheme: String {
        didSet { defaults.set(selectedTheme, forKey: "selectedTheme") }
    }
    @Published var selectedLanguage: String {
        didSet {
            defaults.set(selectedLanguage, forKey: "selectedLanguage")
            languageDidChange.send()
        }
    }
    @Published var preventSleep: Bool {
        didSet {
            defaults.set(preventSleep, forKey: "preventSleep")
            UIApplication.shared.isIdleTimerDisabled = preventSleep
        }
    }

    // Gamepad Settings
    @Published var invertHorizontal: Bool {
        didSet { defaults.set(invertHorizontal, forKey: "invertHorizontal") }
    }
    @Published var invertVertical: Bool {
        didSet { defaults.set(invertVertical, forKey: "invertVertical") }
    }

    // Sliders update only themselves
    @Published var horizontalSensitivity: Double {
        didSet { defaults.set(horizontalSensitivity, forKey: "horizontalSensitivity") }
    }
    @Published var verticalSensitivity: Double {
        didSet { defaults.set(verticalSensitivity, forKey: "verticalSensitivity") }
    }

    let languageDidChange = PassthroughSubject<Void, Never>()

    private let defaults = UserDefaults.standard

    init() {
        // App settings
        vibrationFeedback = defaults.object(forKey: "vibrationFeedback") as? Bool ?? true
        hapticStrength = defaults.string(forKey: "hapticStrength") ?? "Medium"
        soundEffects = defaults.object(forKey: "soundEffects") as? Bool ?? true
        selectedTheme = defaults.string(forKey: "selectedTheme") ?? "Light"
        selectedLanguage = defaults.string(forKey: "selectedLanguage") ?? "English"
        preventSleep = defaults.object(forKey: "preventSleep") as? Bool ?? false

        // Gamepad settings
        invertHorizontal = defaults.object(forKey: "invertHorizontal") as? Bool ?? false
        invertVertical = defaults.object(forKey: "invertVertical") as? Bool ?? false
        horizontalSensitivity = defaults.object(forKey: "horizontalSensitivity") as? Double ?? 1.0
        verticalSensitivity = defaults.object(forKey: "verticalSensitivity") as? Double ?? 1.0

        // Validate language
        let validLanguages = ["English", "French", "Spanish"]
        if !validLanguages.contains(selectedLanguage) {
            selectedLanguage = "English"
            defaults.set(selectedLanguage, forKey: "selectedLanguage")
        }

        // If keys were never set, initialize other defaults
        if defaults.object(forKey: "hasInitializedDefaults") == nil {
            defaults.set(true, forKey: "hasInitializedDefaults")
            resetToDefaults()
        }
    }

    func resetToDefaults() {
        vibrationFeedback = true
        hapticStrength = "Medium"
        soundEffects = true
        selectedTheme = "Light"
        selectedLanguage = "English"
        preventSleep = false
    }

    func resetGamepadDefaults() {
        invertHorizontal = false
        invertVertical = false
        horizontalSensitivity = 1.0
        verticalSensitivity = 1.0
    }

    // Computed bundle for localization
    var bundle: Bundle {
        // For runtime language switching without app restart
        let languageCode: String
        switch selectedLanguage {
        case "French": languageCode = "fr"
        case "Spanish": languageCode = "es"
        default: languageCode = "en"
        }

        // Try to get the bundle for the specific language
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        // Fallback to main bundle if specific language bundle not found
        return .main
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
        Color.red
    }

    var shadowColor: Color {
        selectedTheme == "Dark" ? Color.black.opacity(0.8) : Color.black.opacity(0.06)
    }

    var strokeColor: Color {
        selectedTheme == "Dark" ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
}
