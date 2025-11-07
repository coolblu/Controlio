//
//  HomeView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI
import FirebaseAuth

private enum Theme {
    static let bg = Color(red: 0.957, green: 0.968, blue: 0.980)
    static let card = Color.white
    static let primary = Color.orange
    static let stroke = Color.black.opacity(0.08)
    static let shadow = Color.black.opacity(0.06)
    static let corner: CGFloat = 22
}

private enum Route: Hashable {
    case trackpad
    case gamepad
    case manageProfile
    case appPreferences
    case help
}

final class MCManagerWrapper: ObservableObject {
    let manager = MCManager()
    private var started = false
    func ensureBrowsing() {
        guard !started else { return }
        started = true
        manager.startBrowsing()
    }
}

struct HomeView: View {
    // User manager for display name
    @EnvironmentObject var userManager: UserManager
    @Binding var isLoggedIn: Bool

    // TO-DO: reflect actual connection status of device (right now default is "MacBook Pro")
    @State private var connectedDevice: String? = "MacBook Pro"
    @State private var path = NavigationPath()
    @StateObject private var mcHost = MCManagerWrapper()

    @State private var showMenu = false
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
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
                                        .padding(12)
                                        .background(Circle().fill(.white))
                                        .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
                                        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
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
                            Text("Hi, \(userManager.displayName)!")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Choose your controller.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            // 2x2 Controller cards
                            LazyVGrid(columns: columns, spacing: 20) {
                                ControllerCard(
                                    systemImage: "hand.tap",
                                    title: "Trackpad",
                                    subtitle: "Use your iPhone as a touchpad",
                                    /* start trackpad */
                                    action: { path.append(Route.trackpad) }
                                )
                                
                                ControllerCard(
                                    systemImage: "gamecontroller",
                                    title: "Gamepad",
                                    subtitle: "Twin-stick layout",
                                    action: { path.append(Route.gamepad) }
                                )
                                
                                ControllerCard(
                                    systemImage: "antenna.radiowaves.left.and.right",
                                    title: "Motion",
                                    subtitle: "Use motion to control",
                                    action: { /* start motion */ }
                                )
                                
                                ControllerCard(
                                    systemImage: "steeringwheel",
                                    title: "Racing",
                                    subtitle: "Steer by tilting",
                                    action: { /* start racing */ }
                                )
                            }
                            
                            // Connection status
                            if let connectedDevice {
                                ConnectionBanner(deviceName: connectedDevice)
                            }
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                Button("Disconnect") {
                                    connectedDevice = nil
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Button("Change Device") {
                                    // navigate to device picker
                                }
                                .buttonStyle(OutlineButtonStyle())
                            }
                            
                            // Help link
                            Button(action: {
                                path.append(Route.help)
                            }) {
                                Text("Help & Tips")
                                    .font(.headline)
                                    .underline()
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        }
                        .padding(.horizontal, 20)
                    }
                    .background(Theme.bg.ignoresSafeArea())
                    .onAppear{ mcHost.ensureBrowsing() }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .trackpad:
                            TrackpadView(mc: mcHost.manager)
                        case .gamepad:
                            GamepadView(mc: mcHost.manager)
                        case .manageProfile:
                            ManageProfileView(isLoggedIn: $isLoggedIn)
                        case .appPreferences:
                            AppPreferencesView()
                        case .help:
                            HelpView()
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
            }
        }
    }
}

// Componenets

struct SideMenuView: View {
    @EnvironmentObject var userManager: UserManager
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
                                .foregroundColor(.black)

                            Button(action: {
                                showMenu = false
                                navigateToManageProfile()
                            }) {
                                Text("Manage Profile")
                                    .font(.custom("SF Pro", size: 16))
                                    .underline()
                                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                            }
                        }
                    }

                    MenuButton(icon: "slider.horizontal.3", title: "App Preferences") {
                        showMenu = false
                        navigateToAppPreferences()
                    }

                    MenuButton(icon: "questionmark.circle", title: "Help") {
                        showMenu = false
                        navigateToHelp()
                    }

                    Spacer()

                    HStack {
                        Spacer()
                        MenuButton(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Log Out",
                            outlineColor: .orange,
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
                .background(Color.white)
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
    var foregroundColor: Color = .black
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 8
    var outlineColor: Color? = nil
    var outlineWidth: CGFloat = 0
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .bold
    var fullWidth: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(foregroundColor)
                Text(title)
                    .font(.custom("SF Pro", size: fontSize))
                    .fontWeight(fontWeight)
                    .foregroundColor(foregroundColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor)
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

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(title)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: Theme.shadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct ConnectionBanner: View {
    let deviceName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Connected to: \(deviceName)")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .shadow(color: Theme.shadow, radius: 6, x: 0, y: 2)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.35), radius: 8, x: 0, y: 8)
    }
}

private struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Theme.primary.opacity(configuration.isPressed ? 0.7 : 1.0))
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.primary, lineWidth: 2)
            )
    }
}

//#Preview {
//    HomeView()
//        .previewDisplayName("Home")
//}
