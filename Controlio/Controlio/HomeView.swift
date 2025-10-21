//
//  HomeView.swift
//  Controlio
//
//  Created by Jerry Lin on 10/19/25.
//

import SwiftUI

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
}
struct HomeView: View {
    // TO-DO: reflect the changed name from loginview
    var userName: String = "Name"
    // TO-DO: reflect actual connection status of device (right now default is "MacBook Pro")
    @State private var connectedDevice: String? = "MacBook Pro"
    @State private var path = NavigationPath()
    
    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        NavigationStack (path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Top bar (hamburger and Controlio logo)
                    HStack(alignment: .center) {
                        Button(action: { /* open menu */ }) {
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
                    Text("Hi, \(userName)!")
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
                            action: { /* start gamepad */ }
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
                    Button(action: { /* open help */ }) {
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .trackpad:
                    TrackpadView()
                }
            }
        }
    }
}

// Componenets

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
