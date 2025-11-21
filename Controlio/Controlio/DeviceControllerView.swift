//
//  DeviceControllerView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25.
//

import SwiftUI
import MultipeerConnectivity

struct DeviceControllerView: View {
    @EnvironmentObject var appSettings: AppSettings

    var onNavigateHome: (() -> Void)? = nil
    @State private var showAppPreferences = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DeviceControllerViewModel

    init(onNavigateHome: (() -> Void)? = nil, mcManager: MCManager) {
        self.onNavigateHome = onNavigateHome
        self._viewModel = StateObject(wrappedValue: DeviceControllerViewModel(mcManager: mcManager))
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: AppPreferencesView(),
                isActive: $showAppPreferences
            ) {
                EmptyView()
            }
            .hidden()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 24) {
                            connectedSection
                            availableSection
                        }
                        VStack(spacing: 24) {
                            connectedSection
                            availableSection
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DeviceHelpBottomBar(
                onHomeTap: { onNavigateHome?() },
                onSettingsTap: { showAppPreferences = true },
                onWifiTap: {},
                onHelpTap: { dismiss() },
                palette: DeviceHelpPalette.palette(for: appSettings),
                bundle: appSettings.bundle
            )
        }
        .background(appSettings.bgColor.ignoresSafeArea())
        .navigationTitle(
            NSLocalizedString("Device Controller", bundle: appSettings.bundle, comment: "")
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startBrowsing()
            // Automatically start scanning when the view appears
            viewModel.scanForDevices()
        }
    }

    @ViewBuilder
    private var connectedSection: some View {
        DeviceControllerSection(
            title: NSLocalizedString("Connected Devices", bundle: appSettings.bundle, comment: ""),
            showScanButton: false,
            devices: viewModel.connectedDevices,
            isScanning: false,
            onScanTap: {},
            onDeviceAction: { device in
                viewModel.toggleConnection(for: device)
            },
            onForget: { device in
                viewModel.forget(device)
            }
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }

    @ViewBuilder
    private var availableSection: some View {
        DeviceControllerSection(
            title: NSLocalizedString("Available Devices", bundle: appSettings.bundle, comment: ""),
            showScanButton: true,
            devices: viewModel.availableDevices,
            isScanning: viewModel.isScanning,
            onScanTap: {
                viewModel.scanForDevices()
            },
            onDeviceAction: { device in
                viewModel.toggleConnection(for: device)
            },
            onForget: { device in
                viewModel.forget(device)
            }
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }
}

private struct DeviceControllerSection: View {
    let title: String
    let showScanButton: Bool
    let devices: [DeviceInfo]
    let isScanning: Bool
    let onScanTap: () -> Void
    let onDeviceAction: (DeviceInfo) -> Void
    let onForget: (DeviceInfo) -> Void
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                if showScanButton {
                    Button(action: onScanTap) {
                        HStack(spacing: 8) {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            let scanTitle = isScanning
                                ? NSLocalizedString("Scanning...", bundle: appSettings.bundle, comment: "Indicates scanning in progress")
                                : NSLocalizedString("Scan Devices", bundle: appSettings.bundle, comment: "Button to start device scan")

                            Text(scanTitle)
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(appSettings.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(appSettings.strokeColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isScanning)
                }

            }

            if devices.isEmpty {
                let message = showScanButton
                    ? NSLocalizedString(
                        "No devices found. Tap Scan Devices to refresh.",
                        bundle: appSettings.bundle,
                        comment: "Shown when no available devices are found"
                    )
                    : NSLocalizedString(
                        "No connected devices",
                        bundle: appSettings.bundle,
                        comment: "Shown when there are no currently connected devices"
                    )

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 16) {
                    ForEach(devices) { device in
                        DeviceControllerCard(
                            device: device,
                            onAction: { onDeviceAction(device) }
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                onForget(device)
                            } label: {
                                Label(
                                    NSLocalizedString("Forget Device", bundle: appSettings.bundle, comment: "Context menu action to forget a device"),
                                    systemImage: "trash"
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(appSettings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(appSettings.strokeColor, lineWidth: 1)
        )
        .shadow(color: appSettings.shadowColor, radius: 6, x: 0, y: 4)
    }
}

private struct DeviceControllerCard: View {
    let device: DeviceInfo
    let onAction: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    private var localizedActionTitle: String {
        switch device.connectionStatus {
        case .connected:
            return NSLocalizedString("Disconnect", bundle: appSettings.bundle, comment: "Button to disconnect from device")
        case .available:
            return NSLocalizedString("Connect", bundle: appSettings.bundle, comment: "Button to connect to device")
        case .connecting:
            return NSLocalizedString("Connecting...", bundle: appSettings.bundle, comment: "Disabled button while connecting")
        case .offline:
            return NSLocalizedString("Offline", bundle: appSettings.bundle, comment: "Label for offline device")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                DeviceIcon(kind: device.kind)
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name).font(.headline)
                    Text(
                        NSLocalizedString(
                            device.subtitle,
                            bundle: appSettings.bundle,
                            comment: ""
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: device.connectionStatus)
            }

            Button(action: onAction) {
                Text(localizedActionTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(device.connectionStatus.buttonBackground)
                    .foregroundStyle(device.connectionStatus.buttonForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                device.connectionStatus.buttonBorder,
                                lineWidth: device.connectionStatus.buttonBorderWidth
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!device.connectionStatus.isActionEnabled)
        }
        .padding(16)
        .background(appSettings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(appSettings.strokeColor, lineWidth: 1)
        )
        .shadow(color: appSettings.shadowColor, radius: 10, x: 0, y: 6)
    }
}

private struct DeviceIcon: View {
    let kind: DeviceInfo.Kind
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(appSettings.cardColor)
                .frame(width: 52, height: 52)
            Image(systemName: kind.iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct StatusBadge: View {
    @EnvironmentObject var appSettings: AppSettings

    let status: DeviceConnectionStatus

    private var localizedStatus: String {
        switch status {
        case .connected:
            return NSLocalizedString("Connected", bundle: appSettings.bundle, comment: "Device connection status: connected")
        case .available:
            return NSLocalizedString("Available", bundle: appSettings.bundle, comment: "Device connection status: available")
        case .connecting:
            return NSLocalizedString("Connecting", bundle: appSettings.bundle, comment: "Device connection status: connecting")
        case .offline:
            return NSLocalizedString("Offline", bundle: appSettings.bundle, comment: "Device connection status: offline")
        }
    }
    
    var body: some View {
        Text(localizedStatus.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(status.badgeForeground)
            .background(status.badgeBackground)
            .clipShape(Capsule())
    }
}

private enum DeviceControllerTheme {
    static let danger = Color(red: 0.875, green: 0.157, blue: 0.212)
    static let primary = Color(red: 1.0, green: 0.451, blue: 0.216)
}

//#Preview {
//    NavigationStack {
//        DeviceControllerView()
//    }
//}
