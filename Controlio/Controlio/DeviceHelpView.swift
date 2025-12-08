//
//  DeviceHelpView.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/07/25
//

import SwiftUI

struct DeviceHelpView: View {
    @EnvironmentObject var appSettings: AppSettings
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
                        Text(loc("Device Help"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text(loc("Quick tips to keep your controller paired and working smoothly."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    DeviceHelpSegmentedControl(selection: $selection, palette: palette, bundle: appSettings.bundle)

                    VStack(spacing: 20) {
                        ForEach(DeviceHelpContent.sections(for: selection, bundle: appSettings.bundle, palette: palette)) { section in
                            DeviceHelpCard(section: section, palette: palette)
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
                onHelpTap: {},
                palette: palette,
                bundle: appSettings.bundle
            )
        }
        .background(palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: appSettings.bundle, comment: "")
    }

    private var palette: DeviceHelpPalette {
        DeviceHelpPalette.palette(for: appSettings)
    }
}

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

    func localizedTitle(bundle: Bundle) -> String {
        NSLocalizedString(title, bundle: bundle, comment: "")
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
}

private enum DeviceHelpContent {
    static func sections(for tab: DeviceHelpTab, bundle: Bundle, palette: DeviceHelpPalette) -> [DeviceHelpSection] {
        switch tab {
            case .connection:
                return connectionSections(bundle: bundle, palette: palette)
            case .usage:
                return usageSections(bundle: bundle, palette: palette)
        }
    }

    private static func connectionSections(bundle: Bundle, palette: DeviceHelpPalette) -> [DeviceHelpSection] {
        let t: (String) -> String = { NSLocalizedString($0, bundle: bundle, comment: "") }
        return [
            DeviceHelpSection(
                title: t("Controller Usage"),
                subtitle: t("Set up both Mac receiver and iPhone app for control."),
                iconName: "hand.tap.fill",
                iconColor: palette.orange,
                steps: [
                    DeviceHelpStep(
                        title: t("Run ControlioReceiver first"),
                        detail: t("In Xcode choose Product → Scheme → ControlioReceiver, set Destination to My Mac, and press Run.")
                    ),
                    DeviceHelpStep(
                        title: t("Grant Accessibility permissions"),
                        detail: t("System Settings → Privacy & Security → Accessibility → add the built ControlioReceiver app.")
                    ),
                    DeviceHelpStep(
                        title: t("Locate the build quickly"),
                        detail: t("Use Products → Show Build Folder in Finder, open Debug, and select ControlioReceiver.app when prompted.")
                    ),
                    DeviceHelpStep(
                        title: t("Rerun and detach"),
                        detail: t("After granting access, run again and tap Debug → Detach from ControlioReceiver so it keeps listening.")
                    ),
                    DeviceHelpStep(
                        title: t("Switch to Controlio"),
                        detail: t("Change the active scheme to Controlio to prepare the iOS app.")
                    ),
                    DeviceHelpStep(
                        title: t("Enable Developer Mode"),
                        detail: t("On iPhone open Settings → Privacy & Security → Developer Mode, enable it, and restart if requested.")
                    ),
                    DeviceHelpStep(
                        title: t("Configure signing"),
                        detail: t("Select the Controlio target, open Signing & Capabilities, ensure your team is set, and give the bundle ID a unique suffix.")
                    ),
                    DeviceHelpStep(
                        title: t("Deploy to device"),
                        detail: t("Plug in the iPhone, pick it under Product → Destination, and run the build.")
                    ),
                    DeviceHelpStep(
                        title: t("Trust the developer profile"),
                        detail: t("First run shows a signing warning—on iPhone visit Settings → General → VPN & Device Management and trust Controlio.")
                    ),
                    DeviceHelpStep(
                        title: t("Finalize trackpad access"),
                        detail: t("Run Controlio again, make sure Bluetooth is on for both devices, sign in, open the controller screen, and allow Local Network.")
                    )
                ],
                callout: DeviceHelpCallout(
                    message: t("Leave ControlioReceiver open in the background so the controller reconnects instantly whenever you launch Controlio."),
                    style: .success
                )
            )
        ]
    }

    private static func usageSections(bundle: Bundle, palette: DeviceHelpPalette) -> [DeviceHelpSection] {
        let t: (String) -> String = { NSLocalizedString($0, bundle: bundle, comment: "") }
        return [
            DeviceHelpSection(
                title: t("Trackpad Gestures"),
                subtitle: t("Three gestures are available on the trackpad."),
                iconName: "hand.point.up.left.fill",
                iconColor: palette.orange,
                steps: [
                    DeviceHelpStep(
                        title: t("3-finger swipe left/right"),
                        detail: t("Swipe with three fingers: left = previous tab (Ctrl+Shift+Tab), right = next tab (Ctrl+Tab).")
                    ),
                    DeviceHelpStep(
                        title: t("Right-edge swipe"),
                        detail: t("Start near the right edge and swipe left to open Notification Center.")
                    ),
                    DeviceHelpStep(
                        title: t("5-finger pinch"),
                        detail: t("Pinch in with five fingers to send Cmd+Q (close app).")
                    )
                ],
                callout: DeviceHelpCallout(
                    message: t("After using a gesture, a normal tap should remain a left click. If clicks feel off, tap the Mac trackpad once to reset."),
                    style: .info
                )
            ),
            DeviceHelpSection(
                title: t("Gamepad Usage"),
                subtitle: t("Configure game controls after trackpad setup."),
                iconName: "gamecontroller.fill",
                iconColor: palette.purple,
                steps: [
                    DeviceHelpStep(
                        title: t("Mirror the trackpad prep"),
                        detail: t("Keep ControlioReceiver running with Bluetooth enabled on both devices so controller input reaches your Mac.")
                    ),
                    DeviceHelpStep(
                        title: t("Remap controls as needed"),
                        detail: t("If a game does not already map actions to WASD or arrow keys, open its settings and rebind each action to the matching gamepad input.")
                    ),
                    DeviceHelpStep(
                        title: t("Example mapping"),
                        detail: t("Set the analog stick forward action to send the keyboard input \"W\" (or your preferred key) so forward movement stays responsive.")
                    )
                ],
                callout: DeviceHelpCallout(
                    message: t("Most games remember your custom keybinds, so you only need to map them once per title."),
                    style: .info
                )
            ),
            DeviceHelpSection(
                title: t("Racing Wheel Usage"),
                subtitle: t("Set up your iPhone as a racing wheel controller."),
                iconName: "steeringwheel",
                iconColor: palette.orange,
                steps: [
                    DeviceHelpStep(
                        title: t("Connect like a trackpad"),
                        detail: t("Ensure ControlioReceiver is running on your Mac with Bluetooth enabled on both devices.")
                    ),
                    DeviceHelpStep(
                        title: t("Select Racing Wheel"),
                        detail: t("From the controller selection screen, choose the Racing Wheel option.")
                    ),
                    DeviceHelpStep(
                        title: t("Tilt to steer"),
                        detail: t("Rotate your iPhone like a steering wheel. The tilt angle controls your steering input.")
                    ),
                    DeviceHelpStep(
                        title: t("Use pedal buttons"),
                        detail: t("Tap the on-screen GAS and BRAKE buttons to accelerate and slow down.")
                    ),
                    DeviceHelpStep(
                        title: t("Customize controls"),
                        detail: t("Open Racing Wheel settings to adjust steering sensitivity and remap pedal keys.")
                    )
                ],
                callout: DeviceHelpCallout(
                    message: t("Hold your iPhone in landscape orientation for the most comfortable and responsive steering experience."),
                    style: .info
                )
            )
        ]
    }
}

private struct DeviceHelpSegmentedControl: View {
    @Binding var selection: DeviceHelpTab
    @Namespace private var namespace
    let palette: DeviceHelpPalette
    let bundle: Bundle

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DeviceHelpTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.localizedTitle(bundle: bundle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == tab ? palette.segmentTextActive : palette.segmentTextInactive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selection == tab {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(palette.segmentActive)
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
                .fill(palette.segmentBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.segmentBorder, lineWidth: 1)
        )
    }
}

private struct DeviceHelpCard: View {
    let section: DeviceHelpSection
    let palette: DeviceHelpPalette

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

            VStack(spacing: 14) {
                ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(palette.stepNumber)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(palette.stepBackground)
                            )
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.title)
                                .font(.system(size: 14, weight: .semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(step.detail)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                .foregroundStyle(callout.style == .success ? palette.calloutSuccessForeground : palette.calloutInfoForeground)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(callout.style == .success ? palette.calloutSuccessBackground : palette.calloutInfoBackground)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
        .shadow(color: palette.shadow, radius: 10, x: 0, y: 5)
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
        onHelpTap: @escaping () -> Void = {},
        palette: DeviceHelpPalette,
        bundle: Bundle
    ) {
        self.orientation = orientation
        self.items = [
            .init(systemName: "house.fill", accessibilityLabel: NSLocalizedString("Home", bundle: bundle, comment: ""), action: onHomeTap),
            .init(systemName: "gearshape.fill", accessibilityLabel: NSLocalizedString("Settings", bundle: bundle, comment: ""), action: onSettingsTap),
            .init(systemName: "wifi", accessibilityLabel: NSLocalizedString("Wireless connection", bundle: bundle, comment: ""), action: onWifiTap),
            .init(systemName: "questionmark.circle", accessibilityLabel: NSLocalizedString("Help", bundle: bundle, comment: ""), action: onHelpTap)
        ]
        self.palette = palette
    }

    private let palette: DeviceHelpPalette

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
                    Rectangle()
                        .fill(palette.bottomBarBackground)
                )
                .background(
                    palette.bottomBarBackground
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
                    Rectangle()
                        .fill(palette.bottomBarBackground)
                )
                .background(
                    palette.bottomBarBackground
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
                    .foregroundStyle(palette.bottomIconForeground)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.bottomIconBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(palette.bottomIconStroke, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.accessibilityLabel)
            .frame(maxWidth: .infinity)
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

struct DeviceHelpPalette {
    let background: Color
    let card: Color
    let cardBorder: Color
    let shadow: Color
    let orange: Color
    let purple: Color
    let segmentBackground: Color
    let segmentActive: Color
    let segmentBorder: Color
    let segmentTextActive: Color
    let segmentTextInactive: Color
    let stepBackground: Color
    let stepNumber: Color
    let bottomBarBackground: Color
    let bottomBarShadow: Color
    let bottomIconBackground: Color
    let bottomIconForeground: Color
    let bottomIconStroke: Color
    let bottomIconShadow: Color
    let calloutSuccessBackground: Color
    let calloutSuccessForeground: Color
    let calloutInfoBackground: Color
    let calloutInfoForeground: Color

    static func palette(for settings: AppSettings) -> DeviceHelpPalette {
        let isDark = settings.selectedTheme == "Dark"
        let accent = Color.orange
        let purple = Color(red: 0.498, green: 0.278, blue: 0.851)

        return DeviceHelpPalette(
            background: settings.bgColor,
            card: settings.cardColor,
            cardBorder: isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
            shadow: isDark ? Color.black.opacity(0.55) : Color.black.opacity(0.05),
            orange: accent,
            purple: purple,
            segmentBackground: isDark ? Color.white.opacity(0.06) : Color.white,
            segmentActive: isDark ? accent.opacity(0.18) : Color(red: 0.984, green: 0.890, blue: 0.784),
            segmentBorder: isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05),
            segmentTextActive: isDark ? accent : Color(red: 0.424, green: 0.251, blue: 0.047),
            segmentTextInactive: Color.secondary,
            stepBackground: isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
            stepNumber: isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.7),
            bottomBarBackground: accent,
            bottomBarShadow: isDark ? Color.black.opacity(0.55) : Color.black.opacity(0.08),
            bottomIconBackground: isDark ? Color(red: 0.16, green: 0.16, blue: 0.18) : Color(red: 0.216, green: 0.214, blue: 0.206),
            bottomIconForeground: isDark ? Color.white : Color(red: 0.988, green: 0.965, blue: 0.902),
            bottomIconStroke: Color.white.opacity(0.08),
            bottomIconShadow: isDark ? Color.black.opacity(0.4) : Color.black.opacity(0.25),
            calloutSuccessBackground: isDark ? Color.green.opacity(0.16) : Color(red: 0.835, green: 0.957, blue: 0.862),
            calloutSuccessForeground: isDark ? Color.green.opacity(0.85) : Color(red: 0.113, green: 0.502, blue: 0.263),
            calloutInfoBackground: isDark ? purple.opacity(0.16) : Color(red: 0.949, green: 0.922, blue: 0.996),
            calloutInfoForeground: isDark ? Color.white.opacity(0.9) : Color(red: 0.314, green: 0.200, blue: 0.600)
        )
    }
}

//#Preview {
//    NavigationStack {
//        DeviceHelpView()
//    }
//}
