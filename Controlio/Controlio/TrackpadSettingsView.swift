//
//  TrackpadSettingsView.swift
//  Controlio
//
//  Created by Evan Weng on 11/7/25.
//

import SwiftUI

struct TrackpadSettingsView: View {
    var onNavigateHome: (() -> Void)? = nil
    let mcManager: MCManager
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings

    @Binding var pointerSensitivity: Double
    @Binding var scrollSensitivity: Double
    @Binding var reverseScroll: Bool
    
    @State private var showDeviceController = false
    @State private var showDeviceHelp = false
    @State private var showAppPreferences = false

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text(
                        NSLocalizedString("Pointer", bundle: appSettings.bundle, comment: "")
                    )
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(
                                NSLocalizedString("Sensitivity", bundle: appSettings.bundle, comment: "")
                            )
                            Spacer()
                            Text(
                                String(
                                    format: NSLocalizedString("%.1fx", bundle: appSettings.bundle, comment: ""),
                                    pointerSensitivity
                                )
                            )
                            .foregroundColor(.secondary)
                        }
                        Slider(value: $pointerSensitivity, in: 0.5...3.0, step: 0.1)
                    }
                }

                Section(
                    header: Text(
                        NSLocalizedString("Scrolling", bundle: appSettings.bundle, comment: "")
                    )
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(
                                NSLocalizedString("Scroll Speed", bundle: appSettings.bundle, comment: "")
                            )
                            Spacer()
                            Text(
                                String(
                                    format: NSLocalizedString("%.1fx", bundle: appSettings.bundle, comment: ""),
                                    scrollSensitivity
                                )
                            )
                            .foregroundColor(.secondary)
                        }
                        Slider(value: $scrollSensitivity, in: 0.5...3.0, step: 0.1)
                    }

                    Toggle(
                        NSLocalizedString("Reverse Scroll Direction", bundle: appSettings.bundle, comment: ""),
                        isOn: $reverseScroll
                    )
                }

                Section(
                    header: Text(
                        NSLocalizedString("Reset", bundle: appSettings.bundle, comment: "")
                    )
                ) {
                    Button {
                        pointerSensitivity = 1.0
                        scrollSensitivity = 1.0
                        reverseScroll = false
                    } label: {
                        HStack {
                            Spacer()
                            Text(
                                NSLocalizedString("Reset to Defaults", bundle: appSettings.bundle, comment: "")
                            )
                            .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(
                NSLocalizedString("Trackpad Settings", bundle: appSettings.bundle, comment: "")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        NSLocalizedString("Done", bundle: appSettings.bundle, comment: "")
                    ) {
                        dismiss()
                    }
                }
            }
            // 👇 These are now clearly *inside* the NavigationStack content
            .navigationDestination(isPresented: $showDeviceController) {
                DeviceControllerView(onNavigateHome: onNavigateHome, mcManager: mcManager)
            }
            .navigationDestination(isPresented: $showDeviceHelp) {
                DeviceHelpView(onNavigateHome: onNavigateHome, mcManager: mcManager)
            }
            .navigationDestination(isPresented: $showAppPreferences) {
                AppPreferencesView()
            }
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
        }
    }
}
