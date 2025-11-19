//
//  DeviceHelpView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25
//

import SwiftUI

struct DeviceHelpView: View {
    var onNavigateHome: (() -> Void)? = nil
    let mcManager: MCManager
    @State private var selection: DeviceHelpTab = .connection
    @State private var showDeviceController = false
    @State private var showAppPreferences = false

    var body: some View {
        ZStack {
            NavigationLink(
                destination: DeviceControllerView(onNavigateHome: onNavigateHome, mcManager: mcManager),
                isActive: $showDeviceController
            ) {
                EmptyView()
            }
            .hidden()
            NavigationLink(
                destination: AppPreferencesView(),
                isActive: $showAppPreferences
            ) {
                EmptyView()
            }
            .hidden()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Help")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Quick tips to keep your controller paired and working smoothly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    DeviceHelpSegmentedControl(selection: $selection)

                    VStack(spacing: 20) {
                        ForEach(selection.sections) { section in
                            DeviceHelpCard(section: section)
                        }
                    }
                }
            }
        }
        .padding(20)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DeviceHelpBottomBar(
                onHomeTap: { onNavigateHome?() },
                onSettingsTap: { showAppPreferences = true },
                onWifiTap: { showDeviceController = true },
                onHelpTap: {}
            )
        }
        .background(DeviceHelpTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data

private enum DeviceHelpTab: CaseIterable, Identifiable {
    case connection
    case usage

    var id: Self { self }

    var title: String {
        switch self {
        case .connection: return "Device Connection"
        case .usage: return "Controller Usage"
        }
    }

    var sections: [DeviceHelpSection] {
        switch self {
        case .connection: return DeviceHelpContent.connectionSections
        case .usage: return DeviceHelpContent.usageSections
        }
    }
}

private struct DeviceHelpSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    let steps: [DeviceHelpStep]
    let callout: DeviceHelpCallout?
}

private struct DeviceHelpStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

private struct DeviceHelpCallout {
    enum Style {
        case success
        case info
    }

    let message: String
    let style: Style

    var iconName: String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .info: return "lightbulb.fill"
        }
    }

    var background: Color {
        switch style {
        case .success: return Color(red: 0.835, green: 0.957, blue: 0.862)
        case .info: return Color(red: 0.949, green: 0.922, blue: 0.996)
        }
    }

    var foreground: Color {
        switch style {
        case .success: return Color(red: 0.113, green: 0.502, blue: 0.263)
        case .info: return Color(red: 0.314, green: 0.200, blue: 0.600)
        }
    }
}

private enum DeviceHelpContent {
    static let connectionSections: [DeviceHelpSection] = [
        DeviceHelpSection(
            title: "USB Connection",
            subtitle: "Connect your controller directly via USB cable for the most reliable connection.",
            iconName: "cable.connector.horizontal",
            iconColor: DeviceHelpTheme.orange,
            steps: [
                DeviceHelpStep(
                    title: "Connect your controller using a data-capable USB cable",
                    detail: "Make sure the cable supports data transfer, not just charging."
                ),
                DeviceHelpStep(
                    title: "Wait for your system to recognize the device",
                    detail: "macOS installs any required drivers automatically."
                ),
                DeviceHelpStep(
                    title: "Open Controlio",
                    detail: "Tap the Wi-Fi icon inside the app to confirm the controller is now paired."
                )
            ],
            callout: DeviceHelpCallout(
                message: "USB connection provides the lowest latency and most stable experience.",
                style: .success
            )
        ),
        DeviceHelpSection(
            title: "Bluetooth Connection",
            subtitle: "Connect wirelessly via Bluetooth for a cable-free experience.",
            iconName: "bolt.horizontal.circle",
            iconColor: DeviceHelpTheme.purple,
            steps: [
                DeviceHelpStep(
                    title: "Put your controller into pairing mode",
                    detail: "Hold the share + PS buttons (or equivalent) until the light blinks rapidly."
                ),
                DeviceHelpStep(
                    title: "Pair from Control Center",
                    detail: "Open Settings → Bluetooth and select your controller from the list."
                ),
                DeviceHelpStep(
                    title: "Reconnect inside Controlio",
                    detail: "Return to Controlio and tap the Bluetooth icon to finish pairing."
                )
            ],
            callout: DeviceHelpCallout(
                message: "Wireless is great on-the-go, but keep your device charged for the best results.",
                style: .info
            )
        )
    ]

    static let usageSections: [DeviceHelpSection] = [
        DeviceHelpSection(
            title: "Controller Layout",
            subtitle: "Familiarize yourself with the twin-stick layout before launching a session.",
            iconName: "gamecontroller.fill",
            iconColor: DeviceHelpTheme.orange,
            steps: [
                DeviceHelpStep(
                    title: "Left stick for movement",
                    detail: "Drag anywhere on the left pad to move your pointer or character."
                ),
                DeviceHelpStep(
                    title: "Right stick for camera",
                    detail: "The right pad handles camera or cursor precision adjustments."
                ),
                DeviceHelpStep(
                    title: "Action buttons stay contextual",
                    detail: "Controlio updates button labels depending on the active game or mode."
                )
            ],
            callout: DeviceHelpCallout(
                message: "Customize button mapping from Settings → Controller to match your style.",
                style: .info
            )
        ),
        DeviceHelpSection(
            title: "Quick Gestures",
            subtitle: "Gestures keep common actions within thumb reach.",
            iconName: "hand.tap.fill",
            iconColor: DeviceHelpTheme.purple,
            steps: [
                DeviceHelpStep(
                    title: "Double tap for pause",
                    detail: "Anywhere on the trackpad will trigger the pause overlay."
                ),
                DeviceHelpStep(
                    title: "Two-finger swipe for volume",
                    detail: "Swipe up or down with two fingers to adjust system volume."
                ),
                DeviceHelpStep(
                    title: "Long press to recalibrate",
                    detail: "Hold three fingers for two seconds to reset the gyro baseline."
                )
            ],
            callout: nil
        )
    ]
}

// MARK: - Components

private struct DeviceHelpSegmentedControl: View {
    @Binding var selection: DeviceHelpTab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DeviceHelpTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == tab ? DeviceHelpTheme.segmentTextActive : DeviceHelpTheme.segmentTextInactive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selection == tab {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(DeviceHelpTheme.segmentActive)
                                        .matchedGeometryEffect(id: "selection", in: namespace)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DeviceHelpTheme.segmentBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DeviceHelpTheme.segmentBorder, lineWidth: 1)
        )
    }
}

private struct DeviceHelpCard: View {
    let section: DeviceHelpSection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(section.iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: section.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(section.iconColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                    Text(section.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 16) {
                ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DeviceHelpTheme.stepNumber)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(DeviceHelpTheme.stepBackground)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                            Text(step.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let callout = section.callout {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: callout.iconName)
                        .font(.system(size: 18, weight: .semibold))
                    Text(callout.message)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(callout.foreground)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(callout.background)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DeviceHelpTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DeviceHelpTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: DeviceHelpTheme.shadow, radius: 10, x: 0, y: 5)
    }
}

struct DeviceHelpBottomBar: View {
    enum Orientation {
        case horizontal
        case vertical
    }

    private let items: [DeviceHelpBottomBarItem]
    private let orientation: Orientation

    init(
        orientation: Orientation = .horizontal,
        onHomeTap: @escaping () -> Void = {},
        onSettingsTap: @escaping () -> Void = {},
        onWifiTap: @escaping () -> Void = {},
        onHelpTap: @escaping () -> Void = {}
    ) {
        self.orientation = orientation
        self.items = [
            .init(systemName: "house.fill", accessibilityLabel: "Home", action: onHomeTap),
            .init(systemName: "gearshape.fill", accessibilityLabel: "Settings", action: onSettingsTap),
            .init(systemName: "wifi", accessibilityLabel: "Wireless connection", action: onWifiTap),
            .init(systemName: "questionmark.circle", accessibilityLabel: "Help", action: onHelpTap)
        ]
    }

    var body: some View {
        Group {
            switch orientation {
            case .horizontal:
                HStack(spacing: 20) {
                    toolbarButtons
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 12)
                .background(
                    TopRoundedRectangle(radius: 34)
                        .fill(DeviceHelpTheme.bottomBarBackground)
                        .shadow(color: DeviceHelpTheme.bottomBarShadow, radius: 10, x: 0, y: -2)
                )
                .background(
                    DeviceHelpTheme.bottomBarBackground
                        .ignoresSafeArea(edges: .bottom)
                )

            case .vertical:
                VStack(spacing: 20) {
                    toolbarButtons
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 12)
                .frame(width: 104)
                .background(
                    RightRoundedRectangle(radius: 34)
                        .fill(DeviceHelpTheme.bottomBarBackground)
                        .shadow(color: DeviceHelpTheme.bottomBarShadow, radius: 8, x: -2, y: 0)
                )
                .background(
                    DeviceHelpTheme.bottomBarBackground
                        .ignoresSafeArea(edges: .trailing)
                )
            }
        }
    }

    @ViewBuilder
    private var toolbarButtons: some View {
        ForEach(items) { item in
            Button(action: item.action) {
                Image(systemName: item.systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DeviceHelpTheme.bottomIconForeground)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(DeviceHelpTheme.bottomIconBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(DeviceHelpTheme.bottomIconStroke, lineWidth: 1)
                            )
                    )
                    .shadow(color: DeviceHelpTheme.bottomIconShadow, radius: 6, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.accessibilityLabel)
        }
    }
}

private struct DeviceHelpBottomBarItem: Identifiable {
    let id = UUID()
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void
}

private struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let corner = min(min(radius, height / 2), width / 2)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: corner))
        path.addQuadCurve(to: CGPoint(x: corner, y: 0), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width - corner, y: 0))
        path.addQuadCurve(to: CGPoint(x: width, y: corner), control: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

private struct RightRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let corner = min(min(radius, width / 2), height / 2)

        var path = Path()
        path.move(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: corner, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: corner), control: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height - corner))
        path.addQuadCurve(to: CGPoint(x: corner, y: height), control: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Theme

enum DeviceHelpTheme {
    static let background = Color(red: 0.953, green: 0.965, blue: 0.980)
    static let card = Color.white
    static let cardBorder = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.04)
    static let orange = Color(red: 0.996, green: 0.529, blue: 0.188)
    static let purple = Color(red: 0.498, green: 0.278, blue: 0.851)
    static let segmentBackground = Color.white
    static let segmentActive = Color(red: 0.984, green: 0.890, blue: 0.784)
    static let segmentBorder = Color.black.opacity(0.05)
    static let segmentTextActive = Color(red: 0.424, green: 0.251, blue: 0.047)
    static let segmentTextInactive = Color.secondary
    static let stepBackground = Color.black.opacity(0.04)
    static let stepNumber = Color.black.opacity(0.7)
    static let bottomBarBackground = orange
    static let bottomBarShadow = Color.black.opacity(0.08)
    static let bottomIconBackground = Color(red: 0.216, green: 0.214, blue: 0.206)
    static let bottomIconForeground = Color(red: 0.988, green: 0.965, blue: 0.902)
    static let bottomIconStroke = Color.white.opacity(0.08)
    static let bottomIconShadow = Color.black.opacity(0.25)
}

//#Preview {
//    NavigationStack {
//        DeviceHelpView()
//    }
//}
