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

    // Key Bindings (maps gamepad button names to keyboard keys)
    @Published var keyBindings: [String: String] {
        didSet { defaults.set(keyBindings, forKey: "gamepadKeyBindings") }
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
        keyBindings = defaults.object(forKey: "gamepadKeyBindings") as? [String: String] ?? Self.defaultKeyBindings

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
        keyBindings = Self.defaultKeyBindings
    }

    static let defaultKeyBindings: [String: String] = [
        "A": "Space",
        "B": "E",
        "X": "R",
        "Y": "Q",
        "L1": "1",
        "R1": "2",
        "Start": "Return",
        "Select": "Tab",
        "DPad Up": "W",
        "DPad Down": "S",
        "DPad Left": "A",
        "DPad Right": "D",
        "Left Stick Up": "W",
        "Left Stick Down": "S",
        "Left Stick Left": "A",
        "Left Stick Right": "D",
        "Right Stick Up": "Up",
        "Right Stick Down": "Down",
        "Right Stick Left": "Left",
        "Right Stick Right": "Right"
    ]

    static let availableKeys: [String] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "Space", "Return", "Tab", "Escape", "Shift", "Control", "Option", "Command",
        "Up", "Down", "Left", "Right",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
    ]

    static let gamepadButtons: [String] = [
        "A", "B", "X", "Y", "L1", "R1", "Start", "Select",
        "DPad Up", "DPad Down", "DPad Left", "DPad Right",
        "Left Stick Up", "Left Stick Down", "Left Stick Left", "Left Stick Right",
        "Right Stick Up", "Right Stick Down", "Right Stick Left", "Right Stick Right"
    ]

    // CGKeyCode values for keyboard keys (macOS virtual key codes)
    static let keyCodeMap: [String: Int] = [
        "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4,
        "I": 34, "J": 38, "K": 40, "L": 37, "M": 46, "N": 45, "O": 31, "P": 35,
        "Q": 12, "R": 15, "S": 1, "T": 17, "U": 32, "V": 9, "W": 13, "X": 7,
        "Y": 16, "Z": 6,
        "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26,
        "8": 28, "9": 25,
        "Space": 49, "Return": 36, "Tab": 48, "Escape": 53,
        "Shift": 56, "Control": 59, "Option": 58, "Command": 55,
        "Up": 126, "Down": 125, "Left": 123, "Right": 124,
        "F1": 122, "F2": 120, "F3": 99, "F4": 118, "F5": 96, "F6": 97,
        "F7": 98, "F8": 100, "F9": 101, "F10": 109, "F11": 103, "F12": 111
    ]

    // Returns the CGKeyCode for a gamepad button 
    // based on current key bindings
    func keyCodeForButton(_ buttonName: String) -> Int? {
        guard let keyName = keyBindings[buttonName] ?? Self.defaultKeyBindings[buttonName] else {
            return nil
        }
        return Self.keyCodeMap[keyName]
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
