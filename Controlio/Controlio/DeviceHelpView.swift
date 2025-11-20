//
//  DeviceHelpView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25
//

import SwiftUI
import UIKit

struct DeviceHelpView: View {
    var onNavigateHome: (() -> Void)? = nil
    let mcManager: MCManager
    @State private var selection: DeviceHelpTab = .connection
    @State private var showDeviceController = false
    @State private var showAppPreferences = false
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Device Help", bundle: appSettings.bundle, comment: "Main title for device help screen"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("Quick tips to keep your controller paired and working smoothly.", bundle: appSettings.bundle, comment: "Subtitle for device help screen"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)

                DeviceHelpSegmentedControl(selection: $selection)

                VStack(spacing: 20) {
                    ForEach(selection.sections(bundle: appSettings.bundle)) { section in
                        DeviceHelpCard(section: section)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
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
            DeviceControllerView(onNavigateHome: onNavigateHome, mcManager: mcManager)
        }
        .navigationDestination(isPresented: $showAppPreferences) {
            AppPreferencesView()
        }
    }
}

private enum DeviceHelpTab: CaseIterable, Identifiable {
    case connection
    case usage

    var id: Self { self }

    func title(bundle: Bundle) -> String {
        switch self {
        case .connection: return NSLocalizedString("Device Connection", bundle: bundle, comment: "Tab title for device connection help")
        case .usage: return NSLocalizedString("Controller Usage", bundle: bundle, comment: "Tab title for controller usage help")
        }
    }

    func sections(bundle: Bundle) -> [DeviceHelpSection] {
        switch self {
        case .connection: return DeviceHelpContent.connectionSections(bundle: bundle)
        case .usage: return DeviceHelpContent.usageSections(bundle: bundle)
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
        case .success: return Color.green.opacity(0.15)
        case .info: return Color.purple.opacity(0.15)
        }
    }

    var foreground: Color {
        switch style {
        case .success: return Color.green
        case .info: return Color.purple
        }
    }
}

private enum DeviceHelpContent {
    static func connectionSections(bundle: Bundle) -> [DeviceHelpSection] {
        [DeviceHelpSection(
            title: NSLocalizedString("Trackpad Usage", bundle: bundle, comment: "Section title for trackpad usage help"),
            subtitle: NSLocalizedString("Set up both Mac receiver and iPhone app for trackpad control.", bundle: bundle, comment: "Section subtitle for trackpad usage help"),
            iconName: "macbook.and.iphone",
            iconColor: DeviceHelpTheme.orange,
            steps: [
                DeviceHelpStep(
                    title: NSLocalizedString("Run ControlioReceiver first", bundle: bundle, comment: "Step title for running receiver"),
                    detail: NSLocalizedString("In Xcode choose Product → Scheme → ControlioReceiver, set Destination to My Mac, and press Run.", bundle: bundle, comment: "Step detail for running receiver")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Grant Accessibility permissions", bundle: bundle, comment: "Step title for granting permissions"),
                    detail: NSLocalizedString("System Settings → Privacy & Security → Accessibility → add the built ControlioReceiver app.", bundle: bundle, comment: "Step detail for granting permissions")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Locate the build quickly", bundle: bundle, comment: "Step title for locating build"),
                    detail: NSLocalizedString("Use Products → Show Build Folder in Finder, open Debug, and select ControlioReceiver.app when prompted.", bundle: bundle, comment: "Step detail for locating build")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Rerun and detach", bundle: bundle, comment: "Step title for rerun and detach"),
                    detail: NSLocalizedString("After granting access, run again and tap Debug → Detach from ControlioReceiver so it keeps listening.", bundle: bundle, comment: "Step detail for rerun and detach")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Switch to Controlio", bundle: bundle, comment: "Step title for switching to Controlio"),
                    detail: NSLocalizedString("Change the active scheme to Controlio to prepare the iOS app.", bundle: bundle, comment: "Step detail for switching to Controlio")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Enable Developer Mode", bundle: bundle, comment: "Step title for enabling developer mode"),
                    detail: NSLocalizedString("On iPhone open Settings → Privacy & Security → Developer Mode, enable it, and restart if requested.", bundle: bundle, comment: "Step detail for enabling developer mode")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Configure signing", bundle: bundle, comment: "Step title for configuring signing"),
                    detail: NSLocalizedString("Select the Controlio target, open Signing & Capabilities, ensure your team is set, and give the bundle ID a unique suffix.", bundle: bundle, comment: "Step detail for configuring signing")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Deploy to device", bundle: bundle, comment: "Step title for deploying to device"),
                    detail: NSLocalizedString("Plug in the iPhone, pick it under Product → Destination, and run the build.", bundle: bundle, comment: "Step detail for deploying to device")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Trust the developer profile", bundle: bundle, comment: "Step title for trusting developer profile"),
                    detail: NSLocalizedString("First run shows a signing warning—on iPhone visit Settings → General → VPN & Device Management and trust Controlio.", bundle: bundle, comment: "Step detail for trusting developer profile")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Finalize trackpad access", bundle: bundle, comment: "Step title for finalizing trackpad access"),
                    detail: NSLocalizedString("Run Controlio again, make sure Bluetooth is on for both devices, sign in, open the trackpad screen, and allow Local Network.", bundle: bundle, comment: "Step detail for finalizing trackpad access")
                )
            ],
            callout: DeviceHelpCallout(
                message: NSLocalizedString("Leave ControlioReceiver open in the background so the trackpad reconnects instantly whenever you launch Controlio.", bundle: bundle, comment: "Callout message for trackpad usage"),
                style: .success
            )
        )]
    }

    static func usageSections(bundle: Bundle) -> [DeviceHelpSection] {
        [DeviceHelpSection(
            title: NSLocalizedString("Gamepad Usage", bundle: bundle, comment: "Section title for gamepad usage help"),
            subtitle: NSLocalizedString("Configure game controls after trackpad setup.", bundle: bundle, comment: "Section subtitle for gamepad usage help"),
            iconName: "gamecontroller.fill",
            iconColor: DeviceHelpTheme.purple,
            steps: [
                DeviceHelpStep(
                    title: NSLocalizedString("Mirror the trackpad prep", bundle: bundle, comment: "Step title for mirroring trackpad prep"),
                    detail: NSLocalizedString("Keep ControlioReceiver running with Bluetooth enabled on both devices so controller input reaches your Mac.", bundle: bundle, comment: "Step detail for mirroring trackpad prep")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Remap controls as needed", bundle: bundle, comment: "Step title for remapping controls"),
                    detail: NSLocalizedString("If a game does not already map actions to WASD or arrow keys, open its settings and rebind each action to the matching gamepad input.", bundle: bundle, comment: "Step detail for remapping controls")
                ),
                DeviceHelpStep(
                    title: NSLocalizedString("Example mapping", bundle: bundle, comment: "Step title for example mapping"),
                    detail: NSLocalizedString("Set the analog stick forward action to send the keyboard input \"W\" (or your preferred key) so forward movement stays responsive.", bundle: bundle, comment: "Step detail for example mapping")
                )
            ],
            callout: DeviceHelpCallout(
                message: NSLocalizedString("Most games remember your custom keybinds, so you only need to map them once per title.", bundle: bundle, comment: "Callout message for gamepad usage"),
                style: .info
            )
        )]
    }
}

private struct DeviceHelpSegmentedControl: View {
    @Binding var selection: DeviceHelpTab
    @Namespace private var namespace
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DeviceHelpTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.title(bundle: appSettings.bundle))
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
                                    .fill(Color(uiColor: .systemBackground))
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

    @EnvironmentObject var appSettings: AppSettings
    private let orientation: Orientation
    private let onHomeTap: () -> Void
    private let onSettingsTap: () -> Void
    private let onWifiTap: () -> Void
    private let onHelpTap: () -> Void

    init(
        orientation: Orientation = .horizontal,
        onHomeTap: @escaping () -> Void = {},
        onSettingsTap: @escaping () -> Void = {},
        onWifiTap: @escaping () -> Void = {},
        onHelpTap: @escaping () -> Void = {}
    ) {
        self.orientation = orientation
        self.onHomeTap = onHomeTap
        self.onSettingsTap = onSettingsTap
        self.onWifiTap = onWifiTap
        self.onHelpTap = onHelpTap
    }

    private var items: [DeviceHelpBottomBarItem] {
        [
            .init(systemName: "house.fill", accessibilityLabel: NSLocalizedString("Home", bundle: appSettings.bundle, comment: "Home button accessibility label"), action: onHomeTap),
            .init(systemName: "gearshape.fill", accessibilityLabel: NSLocalizedString("Settings", bundle: appSettings.bundle, comment: "Settings button accessibility label"), action: onSettingsTap),
            .init(systemName: "wifi", accessibilityLabel: NSLocalizedString("Wireless connection", bundle: appSettings.bundle, comment: "WiFi button accessibility label"), action: onWifiTap),
            .init(systemName: "questionmark.circle", accessibilityLabel: NSLocalizedString("Help", bundle: appSettings.bundle, comment: "Help button accessibility label"), action: onHelpTap)
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

enum DeviceHelpTheme {
    // Main colors
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let cardBorder = Color(.separator).opacity(0.5)
    static let shadow = Color.black.opacity(0.04)

    // Brand colors that work in both modes
    static let orange = Color.orange
    static let purple = Color.purple

    // control colors
    static let segmentBackground = Color(.tertiarySystemGroupedBackground)
    static let segmentActive = Color.accentColor.opacity(0.2)
    static let segmentBorder = Color(.separator).opacity(0.3)
    static let segmentTextActive = Color.accentColor
    static let segmentTextInactive = Color.secondary

    // Step colors (better visibility in dark mode)
    static let stepBackground = Color(.systemFill)
    static let stepNumber = Color.primary
    static let stepBorder = Color(.separator)

    // Bottom bar colors - using dynamic colors
    static let bottomBarBackground = Color(.secondarySystemBackground)
    static let bottomBarShadow = Color.black.opacity(0.08)
    static let bottomIconBackground = Color(.tertiarySystemFill)
    static let bottomIconForeground = Color.primary
    static let bottomIconStroke = Color(.separator).opacity(0.3)
    static let bottomIconShadow = Color.black.opacity(0.1)
}

