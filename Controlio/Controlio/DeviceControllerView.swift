//
//  DeviceControllerView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25.
//

import SwiftUI
import MultipeerConnectivity

struct DeviceControllerView: View {
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
                    Text("Device Controller")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

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
                onHelpTap: { dismiss() }
            )
        }
        .background(DeviceHelpTheme.background.ignoresSafeArea())
        .navigationTitle("Device Controller")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startBrowsing()
            // Automatically start scanning when the view appears
            viewModel.scanForDevices()
        }
        .onDisappear {
            viewModel.stopBrowsing()
        }
    }

    @ViewBuilder
    private var connectedSection: some View {
        DeviceControllerSection(
            title: "Connected Devices",
            showScanButton: false,
            devices: viewModel.connectedDevices,
            isScanning: false,
            onScanTap: {},
            onDeviceAction: { device in
                viewModel.toggleConnection(for: device)
            }
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }

    @ViewBuilder
    private var availableSection: some View {
        DeviceControllerSection(
            title: "Available Devices",
            showScanButton: true,
            devices: viewModel.availableDevices,
            isScanning: viewModel.isScanning,
            onScanTap: {
                viewModel.scanForDevices()
            },
            onDeviceAction: { device in
                viewModel.toggleConnection(for: device)
            }
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }
}

// MARK: - Section

private struct DeviceControllerSection: View {
    let title: String
    let showScanButton: Bool
    let devices: [DeviceInfo]
    let isScanning: Bool
    let onScanTap: () -> Void
    let onDeviceAction: (DeviceInfo) -> Void

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
                            Text(isScanning ? "Scanning..." : "Scan Devices")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(DeviceControllerTheme.scanButtonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(DeviceControllerTheme.scanButtonBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isScanning)
                }
            }

            if devices.isEmpty {
                Text(showScanButton ? "No devices found. Tap Scan Devices to refresh." : "No connected devices")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    ForEach(devices) { device in
                        DeviceControllerCard(
                            device: device,
                            onAction: { onDeviceAction(device) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(DeviceControllerTheme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(DeviceControllerTheme.sectionBorder, lineWidth: 1)
        )
    }
}

// MARK: - Card

private struct DeviceControllerCard: View {
    let device: DeviceInfo
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                DeviceIcon(kind: device.kind)
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                    Text(device.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: device.connectionStatus)
            }

            Button(action: onAction) {
                Text(device.connectionStatus.actionTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(device.connectionStatus.buttonBackground)
                    .foregroundStyle(device.connectionStatus.buttonForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(device.connectionStatus.buttonBorder, lineWidth: device.connectionStatus.buttonBorderWidth)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(DeviceControllerTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(DeviceControllerTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: DeviceControllerTheme.cardShadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - Components

private struct DeviceIcon: View {
    let kind: DeviceInfo.Kind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DeviceControllerTheme.iconBackground)
                .frame(width: 52, height: 52)
            Image(systemName: kind.iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DeviceControllerTheme.primary)
        }
    }
}

private struct StatusBadge: View {
    let status: DeviceConnectionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.bold))
            .textCase(.lowercase)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(status.badgeBackground)
            .foregroundStyle(status.badgeForeground)
            .clipShape(Capsule())
    }
}


// MARK: - Theme

private enum DeviceControllerTheme {
    static let primary = DeviceHelpTheme.orange
    static let sectionBackground = Color.white
    static let sectionBorder = Color.black.opacity(0.05)
    static let cardBackground = Color.white
    static let cardBorder = Color.black.opacity(0.06)
    static let cardShadow = Color.black.opacity(0.05)
    static let iconBackground = Color.white
    static let danger = Color(red: 0.875, green: 0.157, blue: 0.212)
    static let scanButtonBackground = Color.white
    static let scanButtonBorder = Color.black.opacity(0.08)
}

//#Preview {
//    NavigationStack {
//        DeviceControllerView()
//    }
//}