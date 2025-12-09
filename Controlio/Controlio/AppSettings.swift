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

    @Published var steeringSensitivity: Double {
        didSet { defaults.set(steeringSensitivity, forKey: "steeringSensitivity") }
    }
    @Published var steeringDeadzone: Double {
        didSet { defaults.set(steeringDeadzone, forKey: "steeringDeadzone") }
    }
    @Published var invertSteering: Bool {
        didSet { defaults.set(invertSteering, forKey: "invertSteering") }
    }

    @Published var raceWheelReceiverDeadzone: Double {
        didSet { defaults.set(raceWheelReceiverDeadzone, forKey: "raceWheelReceiverDeadzone") }
    }
    @Published var raceWheelHoldThreshold: Double {
        didSet { defaults.set(raceWheelHoldThreshold, forKey: "raceWheelHoldThreshold") }
    }
    @Published var raceWheelTapRate: Double {
        didSet { defaults.set(raceWheelTapRate, forKey: "raceWheelTapRate") }
    }

    @Published var gamepadKeybinds: [String: Int] {
        didSet { defaults.set(gamepadKeybinds, forKey: "gamepadKeybinds") }
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

        // Race Wheel settings
        steeringSensitivity = defaults.object(forKey: "steeringSensitivity") as? Double ?? 1.0
        steeringDeadzone = defaults.object(forKey: "steeringDeadzone") as? Double ?? 0.08
        invertSteering = defaults.object(forKey: "invertSteering") as? Bool ?? false
        raceWheelReceiverDeadzone = defaults.object(forKey: "raceWheelReceiverDeadzone") as? Double ?? 0.40
        raceWheelHoldThreshold = defaults.object(forKey: "raceWheelHoldThreshold") as? Double ?? 0.90
        raceWheelTapRate = defaults.object(forKey: "raceWheelTapRate") as? Double ?? 0.05

        // Gamepad keybinds
        gamepadKeybinds = defaults.object(forKey: "gamepadKeybinds") as? [String: Int] ?? Self.defaultKeybinds

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
        gamepadKeybinds = Self.defaultKeybinds
    }

    static let defaultKeybinds: [String: Int] = [
        "a": 49, // Space
        "b": 11, // B
        "x": 7, // X
        "y": 16, // Y
        "l1": 12, // Q
        "r1": 14, // E
        "start": 53, // Escape
        "select": 51, // Delete
        "dpadUp": 126, // Up Arrow
        "dpadDown": 125, // Down Arrow
        "dpadLeft": 123, // Left Arrow
        "dpadRight": 124, // Right Arrow
        "leftStickUp": 13, // W
        "leftStickDown": 1, // S
        "leftStickLeft": 0, // A
        "leftStickRight": 2, // D
        "rightStickUp": 126, // Up Arrow
        "rightStickDown": 125, // Down Arrow
        "rightStickLeft": 123, // Left Arrow
        "rightStickRight": 124, // Right Arrow
        "raceGas": 13, // W
        "raceBrake": 1 // S
    ]

    func resetRaceWheelDefaults() {
        steeringSensitivity = 1.0
        steeringDeadzone = 0.08
        invertSteering = false
        raceWheelReceiverDeadzone = 0.40
        raceWheelHoldThreshold = 0.90
        raceWheelTapRate = 0.05
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

// Keybind Helpers
extension AppSettings {
    func keybind(for button: String) -> Int {
        gamepadKeybinds[button] ?? Self.defaultKeybinds[button] ?? 0
    }

    func setKeybind(_ keyCode: Int, for button: String) {
        var binds = gamepadKeybinds
        binds[button] = keyCode
        gamepadKeybinds = binds
    }
}

enum KeyCode: Int, CaseIterable, Identifiable {
    // Letters
    case a = 0, s = 1, d = 2, f = 3, h = 4, g = 5, z = 6, x = 7, c = 8, v = 9
    case b = 11, q = 12, w = 13, e = 14, r = 15, y = 16, t = 17, o = 31, u = 32
    case i = 34, p = 35, l = 37, j = 38, k = 40, n = 45, m = 46

    // Numbers
    case one = 18, two = 19, three = 20, four = 21, five = 23, six = 22
    case seven = 26, eight = 28, nine = 25, zero = 29

    // Special
    case space = 49, enter = 36, tab = 48, delete = 51, escape = 53

    // Arrows
    case leftArrow = 123, rightArrow = 124, downArrow = 125, upArrow = 126

    // Modifiers
    case shift = 56, control = 59, option = 58, command = 55

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .a: return "A"
        case .s: return "S"
        case .d: return "D"
        case .f: return "F"
        case .h: return "H"
        case .g: return "G"
        case .z: return "Z"
        case .x: return "X"
        case .c: return "C"
        case .v: return "V"
        case .b: return "B"
        case .q: return "Q"
        case .w: return "W"
        case .e: return "E"
        case .r: return "R"
        case .y: return "Y"
        case .t: return "T"
        case .o: return "O"
        case .u: return "U"
        case .i: return "I"
        case .p: return "P"
        case .l: return "L"
        case .j: return "J"
        case .k: return "K"
        case .n: return "N"
        case .m: return "M"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .zero: return "0"
        case .space: return "Space"
        case .enter: return "Enter"
        case .tab: return "Tab"
        case .delete: return "Delete"
        case .escape: return "Escape"
        case .leftArrow: return "← Arrow"
        case .rightArrow: return "→ Arrow"
        case .downArrow: return "↓ Arrow"
        case .upArrow: return "↑ Arrow"
        case .shift: return "Shift"
        case .control: return "Control"
        case .option: return "Option"
        case .command: return "Command"
        }
    }

    static func displayName(for code: Int) -> String {
        KeyCode(rawValue: code)?.displayName ?? "Key \(code)"
    }

    // Grouped for picker UI
    static var letters: [KeyCode] {
        [.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]
    }

    static var numbers: [KeyCode] {
        [.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
    }

    static var special: [KeyCode] {
        [.space, .enter, .tab, .delete, .escape]
    }

    static var arrows: [KeyCode] {
        [.upArrow, .downArrow, .leftArrow, .rightArrow]
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
