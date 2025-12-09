//
//  GamepadSettingsView.swift
//  Controlio
//
//  Created by Jerry Lin on 11/19/25.
//

import SwiftUI

struct GamepadSettingsView: View {
    var onNavigateHome: (() -> Void)? = nil
    let mcManager: MCManager

    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showDeviceController = false
    @State private var showDeviceHelp = false
    @State private var showAppPreferences = false

    // Local states to reduce frequent UserDefaults writes
    @State private var localHorizontalSensitivity: Double = 1.0
    @State private var localVerticalSensitivity: Double = 1.0

    var body: some View {
        NavigationStack {
            Form {
                // Stick Inversion Section
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Stick Inversion",
                            bundle: appSettings.bundle,
                            comment: "Header for the section controlling stick axis inversion settings"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    Toggle(
                        NSLocalizedString(
                            "Invert Horizontal",
                            bundle: appSettings.bundle,
                            comment: "Toggle to invert horizontal stick movement"
                        ),
                        isOn: $appSettings.invertHorizontal
                    )
                    .listRowBackground(appSettings.cardColor)
                    .foregroundColor(appSettings.primaryText)

                    Toggle(
                        NSLocalizedString(
                            "Invert Vertical",
                            bundle: appSettings.bundle,
                            comment: "Toggle to invert vertical stick movement"
                        ),
                        isOn: $appSettings.invertVertical
                    )
                    .listRowBackground(appSettings.cardColor)
                    .foregroundColor(appSettings.primaryText)
                }
                .listRowBackground(appSettings.cardColor)

                // Stick Sensitivity Section
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Stick Sensitivity",
                            bundle: appSettings.bundle,
                            comment: "Header for the section controlling stick sensitivity settings"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    // Horizontal Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Horizontal Sensitivity",
                                    bundle: appSettings.bundle,
                                    comment: "Label for horizontal stick sensitivity slider"
                                )
                            )
                            .foregroundColor(appSettings.primaryText)
                            Spacer()
                            Text(String(format: "%.1fx", localHorizontalSensitivity))
                                .foregroundColor(appSettings.secondaryText)
                        }
                        Slider(
                            value: $localHorizontalSensitivity,
                            in: 0.5...3.0,
                            step: 0.1,
                            onEditingChanged: { editing in
                                if !editing {
                                    appSettings.horizontalSensitivity = localHorizontalSensitivity
                                }
                            }
                        )
                    }
                    .listRowBackground(appSettings.cardColor)

                    // Vertical Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Vertical Sensitivity",
                                    bundle: appSettings.bundle,
                                    comment: "Label for vertical stick sensitivity slider"
                                )
                            )
                            .foregroundColor(appSettings.primaryText)
                            Spacer()
                            Text(String(format: "%.1fx", localVerticalSensitivity))
                                .foregroundColor(appSettings.secondaryText)
                        }
                        Slider(
                            value: $localVerticalSensitivity,
                            in: 0.5...3.0,
                            step: 0.1,
                            onEditingChanged: { editing in
                                if !editing {
                                    appSettings.verticalSensitivity = localVerticalSensitivity
                                }
                            }
                        )
                    }
                    .listRowBackground(appSettings.cardColor)
                }

                // Keybinds Section
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Button Keybinds",
                            bundle: appSettings.bundle,
                            comment: "Header for the section controlling button to key mappings"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    ForEach(GPButton.configurableButtons, id: \.rawValue) { button in
                        KeybindRow(button: button)
                    }
                }
                .listRowBackground(appSettings.cardColor)

                Section(
                    header: Text(
                        NSLocalizedString(
                            "Stick Keybinds",
                            bundle: appSettings.bundle,
                            comment: "Header for the section controlling analog stick key mappings"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    StickKeybindRow(labelKey: "Left Stick Up", settingsKey: "leftStickUp")
                    StickKeybindRow(labelKey: "Left Stick Down", settingsKey: "leftStickDown")
                    StickKeybindRow(labelKey: "Left Stick Left", settingsKey: "leftStickLeft")
                    StickKeybindRow(labelKey: "Left Stick Right", settingsKey: "leftStickRight")
                    StickKeybindRow(labelKey: "Right Stick Up", settingsKey: "rightStickUp")
                    StickKeybindRow(labelKey: "Right Stick Down", settingsKey: "rightStickDown")
                    StickKeybindRow(labelKey: "Right Stick Left", settingsKey: "rightStickLeft")
                    StickKeybindRow(labelKey: "Right Stick Right", settingsKey: "rightStickRight")
                }
                .listRowBackground(appSettings.cardColor)

                // Reset Section
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Reset",
                            bundle: appSettings.bundle,
                            comment: "Header for the section with the reset button"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    Button {
                        appSettings.resetGamepadDefaults()
                        // Sync local sliders after reset
                        localHorizontalSensitivity = appSettings.horizontalSensitivity
                        localVerticalSensitivity = appSettings.verticalSensitivity
                    } label: {
                        HStack {
                            Spacer()
                            Text(
                                NSLocalizedString(
                                    "Reset to Defaults",
                                    bundle: appSettings.bundle,
                                    comment: "Button label to reset all gamepad settings to default values"
                                )
                            )
                            .foregroundColor(appSettings.destructive)
                            Spacer()
                        }
                    }
                    .listRowBackground(appSettings.cardColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(appSettings.bgColor)
            .navigationTitle(
                NSLocalizedString(
                    "Gamepad Settings",
                    bundle: appSettings.bundle,
                    comment: "Title of the gamepad settings screen"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        NSLocalizedString(
                            "Done",
                            bundle: appSettings.bundle,
                            comment: "Button label to dismiss the settings screen"
                        )
                    ) {
                        dismiss()
                    }
                    .foregroundColor(appSettings.primaryButton)
                }
            }

            // Navigation Destinations
            .navigationDestination(isPresented: $showDeviceController) {
                DeviceControllerView(onNavigateHome: onNavigateHome, mcManager: mcManager)
            }
            .navigationDestination(isPresented: $showDeviceHelp) {
                DeviceHelpView(onNavigateHome: onNavigateHome, mcManager: mcManager)
            }
            .navigationDestination(isPresented: $showAppPreferences) {
                AppPreferencesView()
            }

            // Bottom Bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DeviceHelpBottomBar(
                    onHomeTap: {
                        dismiss()
                        onNavigateHome?()
                    },
                    onSettingsTap: { showAppPreferences = true },
                    onWifiTap: { showDeviceController = true },
                    onHelpTap: { showDeviceHelp = true },
                    palette: DeviceHelpPalette.palette(for: appSettings),
                    bundle: appSettings.bundle
                )
            }
            .onAppear {
                // Initialize local sliders from appSettings
                localHorizontalSensitivity = appSettings.horizontalSensitivity
                localVerticalSensitivity = appSettings.verticalSensitivity
            }
        }
    }
}

private struct KeybindRow: View {
    let button: GPButton
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            Text(button.displayName)
                .foregroundColor(appSettings.primaryText)
            Spacer()
            KeyPicker(
                selectedKey: Binding(
                    get: { appSettings.keybind(for: button.settingsKey) },
                    set: { appSettings.setKeybind($0, for: button.settingsKey) }
                )
            )
        }
        .listRowBackground(appSettings.cardColor)
    }
}

private struct StickKeybindRow: View {
    let labelKey: String
    let settingsKey: String
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            Text(NSLocalizedString(labelKey, bundle: appSettings.bundle, comment: "Stick keybind label"))
                .foregroundColor(appSettings.primaryText)
            Spacer()
            KeyPicker(
                selectedKey: Binding(
                    get: { appSettings.keybind(for: settingsKey) },
                    set: { appSettings.setKeybind($0, for: settingsKey) }
                )
            )
        }
        .listRowBackground(appSettings.cardColor)
    }
}

struct KeyPicker: View {
    @Binding var selectedKey: Int
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Menu {
            Section(NSLocalizedString("Letters", bundle: appSettings.bundle, comment: "Menu section header for letter keys")) {
                ForEach(KeyCode.letters) { key in
                    Button(key.displayName) { selectedKey = key.rawValue }
                }
            }
            Section(NSLocalizedString("Numbers", bundle: appSettings.bundle, comment: "Menu section header for number keys")) {
                ForEach(KeyCode.numbers) { key in
                    Button(key.displayName) { selectedKey = key.rawValue }
                }
            }
            Section(NSLocalizedString("Special", bundle: appSettings.bundle, comment: "Menu section header for special keys")) {
                ForEach(KeyCode.special) { key in
                    Button(key.displayName) { selectedKey = key.rawValue }
                }
            }
            Section(NSLocalizedString("Arrows", bundle: appSettings.bundle, comment: "Menu section header for arrow keys")) {
                ForEach(KeyCode.arrows) { key in
                    Button(key.displayName) { selectedKey = key.rawValue }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(KeyCode.displayName(for: selectedKey))
                    .foregroundColor(appSettings.primaryButton)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(appSettings.secondaryText)
            }
        }
    }
}
