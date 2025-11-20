//
//  DeviceHelpView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25
//

import SwiftUI

struct DeviceHelpView: View {
    var onNavigateHome: (() -> Void)? = nil
    @State private var selection: DeviceHelpTab = .connection
    @State private var showDeviceController = false
    @State private var showAppPreferences = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Help")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Quick tips to keep your controller paired and working smoothly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)

                    DeviceHelpSegmentedControl(selection: $selection)

                    VStack(spacing: 20) {
                        ForEach(selection.sections) { section in
                            DeviceHelpCard(section: section)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
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
        .navigationDestination(isPresented: $showDeviceController) {
            DeviceControllerView(onNavigateHome: onNavigateHome)
        }
        .navigationDestination(isPresented: $showAppPreferences) {
            AppPreferencesView()
        }
    }
}

// data models

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
            title: "Trackpad Usage",
            subtitle: "Set up both Mac receiver and iPhone app for trackpad control.",
            iconName: "macbook.and.iphone",
            iconColor: DeviceHelpTheme.orange,
            steps: [
                DeviceHelpStep(
                    title: "Run ControlioReceiver first",
                    detail: "In Xcode choose Product → Scheme → ControlioReceiver, set Destination to My Mac, and press Run."
                ),
                DeviceHelpStep(
                    title: "Grant Accessibility permissions",
                    detail: "System Settings → Privacy & Security → Accessibility → add the built ControlioReceiver app."
                ),
                DeviceHelpStep(
                    title: "Locate the build quickly",
                    detail: "Use Products → Show Build Folder in Finder, open Debug, and select ControlioReceiver.app when prompted."
                ),
                DeviceHelpStep(
                    title: "Rerun and detach",
                    detail: "After granting access, run again and tap Debug → Detach from ControlioReceiver so it keeps listening."
                ),
                DeviceHelpStep(
                    title: "Switch to Controlio",
                    detail: "Change the active scheme to Controlio to prepare the iOS app."
                ),
                DeviceHelpStep(
                    title: "Enable Developer Mode",
                    detail: "On iPhone open Settings → Privacy & Security → Developer Mode, enable it, and restart if requested."
                ),
                DeviceHelpStep(
                    title: "Configure signing",
                    detail: "Select the Controlio target, open Signing & Capabilities, ensure your team is set, and give the bundle ID a unique suffix."
                ),
                DeviceHelpStep(
                    title: "Deploy to device",
                    detail: "Plug in the iPhone, pick it under Product → Destination, and run the build."
                ),
                DeviceHelpStep(
                    title: "Trust the developer profile",
                    detail: "First run shows a signing warning—on iPhone visit Settings → General → VPN & Device Management and trust Controlio."
                ),
                DeviceHelpStep(
                    title: "Finalize trackpad access",
                    detail: "Run Controlio again, make sure Bluetooth is on for both devices, sign in, open the trackpad screen, and allow Local Network."
                )
            ],
            callout: DeviceHelpCallout(
                message: "Leave ControlioReceiver open in the background so the trackpad reconnects instantly whenever you launch Controlio.",
                style: .success
            )
        )
    ]

    static let usageSections: [DeviceHelpSection] = [
        DeviceHelpSection(
            title: "Gamepad Usage",
            subtitle: "Configure game controls after trackpad setup.",
            iconName: "gamecontroller.fill",
            iconColor: DeviceHelpTheme.purple,
            steps: [
                DeviceHelpStep(
                    title: "Mirror the trackpad prep",
                    detail: "Keep ControlioReceiver running with Bluetooth enabled on both devices so controller input reaches your Mac."
                ),
                DeviceHelpStep(
                    title: "Remap controls as needed",
                    detail: "If a game does not already map actions to WASD or arrow keys, open its settings and rebind each action to the matching gamepad input."
                ),
                DeviceHelpStep(
                    title: "Example mapping",
                    detail: "Set the analog stick forward action to send the keyboard input \"W\" (or your preferred key) so forward movement stays responsive."
                )
            ],
            callout: DeviceHelpCallout(
                message: "Most games remember your custom keybinds, so you only need to map them once per title.",
                style: .info
            )
        )
    ]
}

// Components and Views

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
                        .fixedSize(horizontal: false, vertical: true)
                    Text(section.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 22) {
                ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DeviceHelpTheme.stepNumber)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(DeviceHelpTheme.stepBorder, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                            Text(step.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let callout = section.callout {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: callout.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 20, height: 20)
                    Text(callout.message)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

// Theme

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
    static let stepBorder = Color.black.opacity(0.15)
    static let bottomBarBackground = orange
    static let bottomBarShadow = Color.black.opacity(0.08)
    static let bottomIconBackground = Color(red: 0.216, green: 0.214, blue: 0.206)
    static let bottomIconForeground = Color(red: 0.988, green: 0.965, blue: 0.902)
    static let bottomIconStroke = Color.white.opacity(0.08)
    static let bottomIconShadow = Color.black.opacity(0.25)
}

