//
//  DeviceControllerView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25.
//

import SwiftUI

struct DeviceControllerView: View {
    var onNavigateHome: (() -> Void)? = nil
    @State private var showAppPreferences = false
    @Environment(\.dismiss) private var dismiss
    private let connectedDevices = DeviceControllerContent.connectedDevices
    private let availableDevices = DeviceControllerContent.availableDevices

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
    }

    @ViewBuilder
    private var connectedSection: some View {
        DeviceControllerSection(
            title: "Connected Devices",
            showScanButton: false,
            devices: connectedDevices
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }

    @ViewBuilder
    private var availableSection: some View {
        DeviceControllerSection(
            title: "Available Devices",
            showScanButton: true,
            devices: availableDevices
        )
        .frame(minWidth: 320, maxWidth: .infinity)
    }
}

// MARK: - Section

private struct DeviceControllerSection: View {
    let title: String
    let showScanButton: Bool
    let devices: [DeviceControllerDevice]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                if showScanButton {
                    Button(action: {}) {
                        Label("Scan Devices", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
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
                }
            }

            if devices.isEmpty {
                Text("No devices found. Tap Scan Devices to refresh.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
                    ForEach(devices) { device in
                        DeviceControllerCard(device: device)
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
    let device: DeviceControllerDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
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
                StatusBadge(status: device.status)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Battery")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(device.batteryPercentage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                BatteryBar(level: device.batteryLevel)
            }

            Button(action: {}) {
                Text(device.status.actionTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(device.status.buttonBackground)
                    .foregroundStyle(device.status.buttonForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(device.status.buttonBorder, lineWidth: device.status.buttonBorderWidth)
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
    let kind: DeviceControllerDevice.Kind

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

private struct BatteryBar: View {
    let level: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DeviceControllerTheme.batteryTrack)
                Capsule()
                    .fill(DeviceControllerTheme.primary)
                    .frame(width: max(4, geo.size.width * level))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Models

private struct DeviceControllerDevice: Identifiable {
    enum Kind {
        case laptop
        case desktop

        var iconName: String {
            switch self {
            case .laptop: return "laptopcomputer"
            case .desktop: return "desktopcomputer"
            }
        }
    }

    let id = UUID()
    let name: String
    let subtitle: String
    let kind: Kind
    let batteryLevel: Double
    let status: DeviceConnectionStatus

    var batteryPercentage: String {
        let value = Int((batteryLevel * 100).rounded())
        return "\(value)%"
    }
}

private enum DeviceConnectionStatus {
    case connected
    case available

    var displayName: String {
        switch self {
        case .connected: return "connected"
        case .available: return "available"
        }
    }

    var badgeBackground: Color {
        switch self {
        case .connected: return Color(red: 1.0, green: 0.894, blue: 0.839)
        case .available: return Color(red: 0.862, green: 0.957, blue: 0.882)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .connected: return DeviceControllerTheme.primary
        case .available: return Color(red: 0.129, green: 0.549, blue: 0.184)
        }
    }

    var actionTitle: String {
        switch self {
        case .connected: return "Disconnect"
        case .available: return "Connect"
        }
    }

    var buttonBackground: Color {
        switch self {
        case .connected: return .white
        case .available: return DeviceControllerTheme.primary
        }
    }

    var buttonForeground: Color {
        switch self {
        case .connected: return DeviceControllerTheme.danger
        case .available: return .white
        }
    }

    var buttonBorder: Color {
        switch self {
        case .connected: return DeviceControllerTheme.danger
        case .available: return .clear
        }
    }

    var buttonBorderWidth: CGFloat {
        switch self {
        case .connected: return 1.5
        case .available: return 0
        }
    }
}

// MARK: - Sample Content

private enum DeviceControllerContent {
    static let connectedDevices: [DeviceControllerDevice] = [
        DeviceControllerDevice(
            name: "MacBook Pro 16\"",
            subtitle: "Laptop",
            kind: .laptop,
            batteryLevel: 0.9,
            status: .connected
        )
    ]

    static let availableDevices: [DeviceControllerDevice] = [
        DeviceControllerDevice(
            name: "Dell XPS 13",
            subtitle: "Laptop",
            kind: .laptop,
            batteryLevel: 0.75,
            status: .available
        ),
        DeviceControllerDevice(
            name: "Gaming PC",
            subtitle: "Desktop",
            kind: .desktop,
            batteryLevel: 1.0,
            status: .available
        )
    ]
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
    static let batteryTrack = Color.black.opacity(0.08)
    static let danger = Color(red: 0.875, green: 0.157, blue: 0.212)
    static let scanButtonBackground = Color.white
    static let scanButtonBorder = Color.black.opacity(0.08)
}

//#Preview {
//    NavigationStack {
//        DeviceControllerView()
//    }
//}
