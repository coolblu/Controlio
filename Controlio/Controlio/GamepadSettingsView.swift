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
                    onHelpTap: { showDeviceHelp = true }
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
