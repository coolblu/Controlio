//
//  RaceWheelSettingsView.swift
//  Controlio
//
//  Created by Jerry Lin on 12/7/25.
//

import SwiftUI

struct RaceWheelSettingsView: View {
    var onNavigateHome: (() -> Void)? = nil
    let mcManager: MCManager

    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showDeviceController = false
    @State private var showDeviceHelp = false
    @State private var showAppPreferences = false

    // Local states to reduce frequent UserDefaults writes
    @State private var localSteeringSensitivity: Double = 1.0
    @State private var localSteeringDeadzone: Double = 0.0
    @State private var localReceiverDeadzone: Double = 0.0
    @State private var localHoldThreshold: Double = 0.0
    @State private var localTapRate: Double = 0.0

    var body: some View {
        NavigationStack {
            Form {

                // Steering Inversion
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Steering Direction",
                            bundle: appSettings.bundle,
                            comment: "Header for steering inversion"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    Toggle(
                        NSLocalizedString(
                            "Invert Steering",
                            bundle: appSettings.bundle,
                            comment: "Toggle to invert race wheel steering"
                        ),
                        isOn: $appSettings.invertSteering
                    )
                    .listRowBackground(appSettings.cardColor)
                    .foregroundColor(appSettings.primaryText)
                }

                // Steering Tuning
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Steering Tuning",
                            bundle: appSettings.bundle,
                            comment: "Header for steering tuning section"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {

                    // Steering Sensitivity (default = 1.0 centered)
                    tuningSlider(
                        title: NSLocalizedString("Steering Sensitivity", bundle: appSettings.bundle, comment: "Label for steering sensitivity slider"),
                        value: $localSteeringSensitivity,
                        range: 0.5...2.0,
                        step: 0.05,
                        suffix: "x"
                    ) {
                        appSettings.steeringSensitivity = localSteeringSensitivity
                    }

                    // Steering Deadzone (default = 0.08 centered)
                    tuningSlider(
                        title: NSLocalizedString("Steering Deadzone", bundle: appSettings.bundle, comment: "Label for steering deadzone slider"),
                        value: $localSteeringDeadzone,
                        range: 0.0...0.20,
                        step: 0.01,
                        suffix: "x"
                    ) {
                        appSettings.steeringDeadzone = localSteeringDeadzone
                    }
                }

                // Input Behavior
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Input Behavior",
                            bundle: appSettings.bundle,
                            comment: "Header for input behavior section"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {

                    // Receiver Deadzone (default = 0.40 centered)
                    tuningSlider(
                        title: NSLocalizedString("Receiver Deadzone", bundle: appSettings.bundle, comment: "Label for race wheel receiver deadzone slider"),
                        value: $localReceiverDeadzone,
                        range: 0.10...0.60,
                        step: 0.01,
                        suffix: "x"
                    ) {
                        appSettings.raceWheelReceiverDeadzone = localReceiverDeadzone
                    }

                    // Hold Threshold (default = 0.90 near top)
                    tuningSlider(
                        title: NSLocalizedString("Hold Threshold", bundle: appSettings.bundle, comment: "Label for race wheel hold threshold slider"),
                        value: $localHoldThreshold,
                        range: 0.50...1.00,
                        step: 0.01,
                        suffix: "x"
                    ) {
                        appSettings.raceWheelHoldThreshold = localHoldThreshold
                    }

                    // Tap Rate (default = 0.05 centered low)
                    tuningSlider(
                        title: NSLocalizedString("Tap Rate", bundle: appSettings.bundle, comment: "Label for race wheel tap rate slider"),
                        value: $localTapRate,
                        range: 0.02...0.20,
                        step: 0.01,
                        suffix: "x"
                    ) {
                        appSettings.raceWheelTapRate = localTapRate
                    }
                }

                // Reset Section
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Reset",
                            bundle: appSettings.bundle,
                            comment: "Header for reset section"
                        )
                    )
                    .foregroundColor(appSettings.primaryText)
                ) {
                    Button {
                        appSettings.resetRaceWheelDefaults()

                        localSteeringSensitivity = appSettings.steeringSensitivity
                        localSteeringDeadzone = appSettings.steeringDeadzone
                        localReceiverDeadzone = appSettings.raceWheelReceiverDeadzone
                        localHoldThreshold = appSettings.raceWheelHoldThreshold
                        localTapRate = appSettings.raceWheelTapRate

                    } label: {
                        HStack {
                            Spacer()
                            Text(
                                NSLocalizedString(
                                    "Reset to Defaults",
                                    bundle: appSettings.bundle,
                                    comment: "Reset race wheel settings"
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
                    "Race Wheel Settings",
                    bundle: appSettings.bundle,
                    comment: "Title of race wheel settings screen"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        NSLocalizedString(
                            "Done",
                            bundle: appSettings.bundle,
                            comment: "Dismiss race wheel settings"
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
                localSteeringSensitivity = appSettings.steeringSensitivity
                localSteeringDeadzone = appSettings.steeringDeadzone
                localReceiverDeadzone = appSettings.raceWheelReceiverDeadzone
                localHoldThreshold = appSettings.raceWheelHoldThreshold
                localTapRate = appSettings.raceWheelTapRate
            }
        }
    }

    // Shared Slider Builder
    private func tuningSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String,
        onCommit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString(title, bundle: appSettings.bundle, comment: ""))
                    .foregroundColor(appSettings.primaryText)
                Spacer()
                Text(
                    String(format: suffix.isEmpty ? "%.2f" : "%.2f%@", value.wrappedValue, suffix)
                )
                .foregroundColor(appSettings.secondaryText)
            }
            Slider(
                value: value,
                in: range,
                step: step,
                onEditingChanged: { editing in
                    if !editing {
                        onCommit()
                    }
                }
            )
        }
        .listRowBackground(appSettings.cardColor)
    }
}
