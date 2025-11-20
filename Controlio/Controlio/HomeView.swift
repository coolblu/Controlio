//
//  HomeView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI
import FirebaseAuth
import Combine

private enum Route: Hashable {
    case trackpad
    case gamepad
    case manageProfile
    case appPreferences
    case help
    case deviceController
}

final class MCManagerWrapper: ObservableObject {
    let manager = MCManager()
    private var started = false
    private var cancellable: AnyCancellable?
    init() {
        cancellable = manager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    func ensureBrowsing() {
        guard !started else { return }
        started = true
        manager.startBrowsingIfNeeded()
    }
}

struct HomeView: View {
    // User manager for display name
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appSettings: AppSettings
    @Binding var isLoggedIn: Bool

    @State private var path = NavigationPath()
    @StateObject private var mcHost = MCManagerWrapper()

    @State private var showMenu = false
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        let mc = mcHost.manager
        GeometryReader { geometry in
            ZStack {
                NavigationStack (path: $path) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Top bar (hamburger and Controlio logo)
                            HStack(alignment: .center) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(appSettings.primaryButton)
                                        .padding(12)
                                        .background(Circle().fill(appSettings.cardColor))
                                        .overlay(Circle().stroke(appSettings.strokeColor, lineWidth: 1))
                                        .shadow(color: appSettings.shadowColor, radius: 6, x: 0, y: 2)
                                }
                                Spacer() // create space in the right
                            }
                            .frame(maxWidth: .infinity, minHeight: 80) // reserve height for the logo
                            .overlay(alignment: .center) { // overlay puts it in the middle of the parent's coordinate system
                                Image("gameController")
                                    .resizable()
                                    .frame(width: 107, height: 80)
                            }
                            .padding(.top, 8)
                            
                            // Greetings
                            Text(String(format: NSLocalizedString("Hi, %@!", bundle: appSettings.bundle, comment: ""), userManager.displayName))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(appSettings.primaryText)
                            Text(NSLocalizedString("Choose your controller.", bundle: appSettings.bundle, comment: ""))
                                .font(.title3)
                                .foregroundColor(appSettings.secondaryText)
                            
                            // 2x2 Controller cards
                            LazyVGrid(columns: columns, spacing: 20) {
                                ControllerCard(
                                    systemImage: "hand.tap",
                                    title: NSLocalizedString("Trackpad", bundle: appSettings.bundle, comment: ""),
                                    subtitle: NSLocalizedString("Use your iPhone as a touchpad", bundle: appSettings.bundle, comment: ""),
                                    action: { path.append(Route.trackpad) }
                                )
                                .environmentObject(appSettings)
                                
                                ControllerCard(
                                    systemImage: "gamecontroller",
                                    title: NSLocalizedString("Gamepad", bundle: appSettings.bundle, comment: ""),
                                    subtitle: NSLocalizedString("Twin-stick layout", bundle: appSettings.bundle, comment: ""),
                                    action: { path.append(Route.gamepad) }
                                )
                                .environmentObject(appSettings)
                                
                                ControllerCard(
                                    systemImage: "antenna.radiowaves.left.and.right",
                                    title: NSLocalizedString("Motion", bundle: appSettings.bundle, comment: ""),
                                    subtitle: NSLocalizedString("Use motion to control", bundle: appSettings.bundle, comment: ""),
                                    action: { /* start motion */ }
                                )
                                .environmentObject(appSettings)
                                
                                ControllerCard(
                                    systemImage: "steeringwheel",
                                    title: NSLocalizedString("Racing", bundle: appSettings.bundle, comment: ""),
                                    subtitle: NSLocalizedString("Steer by tilting", bundle: appSettings.bundle, comment: ""),
                                    action: { /* start racing */ }
                                )
                                .environmentObject(appSettings)
                            }
                            
                            // Connection status
                            let isConnected = mc.sessionState == .connected
                            let isConnecting = mc.sessionState == .connecting
                            let wasManuallyDisconnected = mc.manuallyDisconnected
                            let nameNow = mc.connectedDeviceName
                            let nameLast = mc.lastConnectedPeer?.displayName
                            let lastKnown = mc.lastKnownDeviceName

                            if isConnected {
                                ConnectionBanner(deviceName: nameNow ?? NSLocalizedString("Connected", bundle: appSettings.bundle, comment: ""))
                                    .environmentObject(appSettings)
                            } else if isConnecting {
                                let displayName =
                                    nameNow ??
                                    lastKnown ??
                                    nameLast ??
                                    NSLocalizedString("Device", bundle: appSettings.bundle, comment: "")

                                ConnectingBanner(deviceName: displayName)
                                    .environmentObject(appSettings)
                            } else if wasManuallyDisconnected, let last = nameLast {
                                DisconnectedBanner(deviceName: last)
                                    .environmentObject(appSettings)
                            }
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                if isConnected {
                                    Button(NSLocalizedString("Disconnect", bundle: appSettings.bundle, comment: "")) {
                                        mc.userRequestedDisconnect()
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .environmentObject(appSettings)
                                } else if wasManuallyDisconnected, nameLast != nil {
                                    Button(NSLocalizedString("Reconnect", bundle: appSettings.bundle, comment: "")) {
                                        mc.userRequestedReconnect()
                                    }
                                    .buttonStyle(ReconnectButtonStyle())
                                    .environmentObject(appSettings)
                                } else {
                                    Button(NSLocalizedString("Connect", bundle: appSettings.bundle, comment: "")) {
                                        mc.userRequestedReconnect()
                                        if let lastName = mc.lastKnownDeviceName,
                                           let lastPeer = mc.discoveredPeers.first(where: { $0.displayName == lastName }) {
                                            mc.connect(to: lastPeer)
                                        } else if let firstPeer = mc.discoveredPeers.first {
                                            mc.connect(to: firstPeer)
                                        } else {
                                            path.append(Route.deviceController)
                                        }
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .environmentObject(appSettings)
                                }

                                Button(NSLocalizedString("Select Device", bundle: appSettings.bundle, comment: "")) {
                                    path.append(Route.deviceController)
                                }
                                .buttonStyle(OutlineButtonStyle())
                                .environmentObject(appSettings)
                            }
                            
                            // Help link
                            Button(action: {
                                path.append(Route.help)
                            }) {
                                Text(NSLocalizedString("Help & Tips", bundle: appSettings.bundle, comment: ""))
                                    .font(.headline)
                                    .underline()
                                    .foregroundColor(appSettings.secondaryText)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        }
                        .padding(.horizontal, 20)
                    }
                    .background(appSettings.bgColor.ignoresSafeArea())
                    .onAppear { mcHost.ensureBrowsing() }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .trackpad:
                            TrackpadView(mc: mc, onNavigateHome: { path = NavigationPath() })
                        case .gamepad:
                            GamepadView(mc: mc)
                        case .manageProfile:
                            ManageProfileView(isLoggedIn: $isLoggedIn)
                        case .appPreferences:
                            AppPreferencesView()
                        case .help:
                            DeviceHelpView(onNavigateHome: { path = NavigationPath() }, mcManager: mc)
                        case .deviceController:
                            DeviceControllerView(onNavigateHome: { path = NavigationPath() }, mcManager: mc)
                        }
                    }
                }
                
                SideMenuView(
                    isLoggedIn: $isLoggedIn,
                    showMenu: $showMenu,
                    userName: userManager.displayName,
                    navigateToManageProfile: { path.append(Route.manageProfile) },
                    navigateToAppPreferences: { path.append(Route.appPreferences) },
                    navigateToHelp: { path.append(Route.help) }
                )
                .environmentObject(appSettings)
            }
        }
    }
}

// Components
struct SideMenuView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appSettings: AppSettings
    @Binding var isLoggedIn: Bool
    @Binding var showMenu: Bool
    var userName: String = "Name"
    var navigateToManageProfile: () -> Void
    var navigateToAppPreferences: () -> Void
    var navigateToHelp: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let menuWidth = geometry.size.width * 0.6
            let leadingInset = geometry.safeAreaInsets.leading

            ZStack(alignment: .leading) {
                // Semi-transparent background
                if showMenu {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture { showMenu = false }
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.25), value: showMenu)
                }

                // Menu content
                VStack(alignment: .leading, spacing: 16) {
                    // Profile Header
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(userManager.displayName)
                                .font(.custom("SF Pro", size: 18))
                                .foregroundColor(appSettings.primaryText)

                            Button(action: {
                                showMenu = false
                                navigateToManageProfile()
                            }) {
                                Text(NSLocalizedString("Manage Profile", bundle: appSettings.bundle, comment: ""))
                                    .font(.custom("SF Pro", size: 16))
                                    .underline()
                                    .foregroundColor(appSettings.secondaryText)
                            }
                        }
                    }

                    MenuButton(icon: "slider.horizontal.3",
                               title: NSLocalizedString("App Preferences", bundle: appSettings.bundle, comment: "")) {
                        showMenu = false
                        navigateToAppPreferences()
                    }

                    MenuButton(icon: "questionmark.circle",
                               title: NSLocalizedString("Help", bundle: appSettings.bundle, comment: "")) {
                        showMenu = false
                        navigateToHelp()
                    }

                    Spacer()

                    HStack {
                        Spacer()
                        MenuButton(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: NSLocalizedString("Log Out", bundle: appSettings.bundle, comment: ""),
                            outlineColor: appSettings.primaryButton,
                            outlineWidth: 2
                        ) {
                            do {
                                try AuthManager.shared.signOut()
                                showMenu = false
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    isLoggedIn = false
                                }
                            } catch {
                                print("Failed to sign out: \(error.localizedDescription)")
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 50)

                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.leading, leadingInset)
                .frame(width: menuWidth, height: geometry.size.height)
                .background(appSettings.cardColor)
                .offset(x: showMenu ? 0 : -(menuWidth + leadingInset))
                .animation(.easeOut(duration: 0.25), value: showMenu)
                .zIndex(1)
            }
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    var foregroundColor: Color?
    var backgroundColor: Color?
    var cornerRadius: CGFloat = 8
    var outlineColor: Color? = nil
    var outlineWidth: CGFloat = 0
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .bold
    var fullWidth: Bool = false
    var action: () -> Void
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(foregroundColor ?? appSettings.primaryText)
                Text(title)
                    .font(.custom("SF Pro", size: fontSize))
                    .fontWeight(fontWeight)
                    .foregroundColor(foregroundColor ?? appSettings.primaryText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor ?? appSettings.cardColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(outlineColor ?? Color.clear, lineWidth: outlineWidth)
            )
            .cornerRadius(cornerRadius)
        }
    }
}

private struct ControllerCard: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let action: () -> Void
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                    .foregroundColor(appSettings.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(NSLocalizedString(title, bundle: appSettings.bundle, comment: ""))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(appSettings.primaryText)

                Text(NSLocalizedString(subtitle, bundle: appSettings.bundle, comment: ""))
                    .font(.subheadline)
                    .foregroundColor(appSettings.secondaryText)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(appSettings.cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(appSettings.strokeColor, lineWidth: 1)
            )
            .shadow(color: appSettings.shadowColor, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct ConnectionBanner: View {
    let deviceName: String
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(String(format: NSLocalizedString("Connected to: %@", bundle: appSettings.bundle, comment: ""), deviceName))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(appSettings.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(appSettings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(appSettings.strokeColor, lineWidth: 1)
        )
        .shadow(color: appSettings.shadowColor, radius: 6, x: 0, y: 2)
    }
}

private struct ConnectingBanner: View {
    let deviceName: String
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text(String(
                format: NSLocalizedString("Connecting to: %@", bundle: appSettings.bundle, comment: ""),
                deviceName
            ))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(appSettings.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(appSettings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(appSettings.strokeColor, lineWidth: 1)
        )
        .shadow(color: appSettings.shadowColor, radius: 6, x: 0, y: 2)
    }
}

private struct DisconnectedBanner: View {
    let deviceName: String
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
            Text(String(format: NSLocalizedString("Disconnected from: %@", bundle: appSettings.bundle, comment: ""), deviceName))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(appSettings.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(appSettings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(appSettings.strokeColor, lineWidth: 1)
        )
        .shadow(color: appSettings.shadowColor, radius: 6, x: 0, y: 2)
    }
}

private struct ReconnectButtonStyle: ButtonStyle {
    @EnvironmentObject var appSettings: AppSettings
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundColor(appSettings.buttonText)
            .background(Color.orange.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: appSettings.shadowColor, radius: 8, x: 0, y: 8)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var appSettings: AppSettings

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundColor(appSettings.buttonText)
            .background(appSettings.primaryButton.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: appSettings.shadowColor, radius: 8, x: 0, y: 8)
    }
}

private struct OutlineButtonStyle: ButtonStyle {
    @EnvironmentObject var appSettings: AppSettings

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundColor(appSettings.primaryText.opacity(configuration.isPressed ? 0.7 : 1.0))
            .background(appSettings.selectedTheme != "Dark" ? appSettings.cardColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(appSettings.primaryButton, lineWidth: 2)
            )
    }
}

//#Preview {
//    HomeView()
//        .previewDisplayName("Home")
//}
