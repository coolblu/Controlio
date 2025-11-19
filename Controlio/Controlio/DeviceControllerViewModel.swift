//
//  DeviceControllerViewModel.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/19/25.
//

import SwiftUI
import MultipeerConnectivity
import Combine

// MARK: - Device Model
struct DeviceInfo: Identifiable {
    enum Kind {
        case laptop
        case desktop
        case phone
        case unknown

        var iconName: String {
            switch self {
            case .laptop: return "laptopcomputer"
            case .desktop: return "desktopcomputer"
            case .phone: return "iphone"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    let id: String
    let peerID: MCPeerID
    let name: String
    let kind: Kind
    let isConnected: Bool

    var subtitle: String {
        switch kind {
        case .laptop: return "Laptop"
        case .desktop: return "Desktop"
        case .phone: return "Phone"
        case .unknown: return "Device"
        }
    }

    var connectionStatus: DeviceConnectionStatus {
        isConnected ? .connected : .available
    }
}

enum DeviceConnectionStatus {
    case connected
    case available
    case connecting

    var displayName: String {
        switch self {
        case .connected: return "connected"
        case .available: return "available"
        case .connecting: return "connecting..."
        }
    }

    var badgeBackground: Color {
        switch self {
        case .connected: return Color(red: 1.0, green: 0.894, blue: 0.839)
        case .available: return Color(red: 0.862, green: 0.957, blue: 0.882)
        case .connecting: return Color.gray.opacity(0.2)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .connected: return Color(red: 1.0, green: 0.451, blue: 0.216)
        case .available: return Color(red: 0.129, green: 0.549, blue: 0.184)
        case .connecting: return Color.gray
        }
    }

    var actionTitle: String {
        switch self {
        case .connected: return "Disconnect"
        case .available: return "Connect"
        case .connecting: return "Connecting..."
        }
    }

    var buttonBackground: Color {
        switch self {
        case .connected: return .white
        case .available: return Color(red: 1.0, green: 0.451, blue: 0.216)
        case .connecting: return Color.gray.opacity(0.2)
        }
    }

    var buttonForeground: Color {
        switch self {
        case .connected: return Color(red: 0.875, green: 0.157, blue: 0.212)
        case .available: return .white
        case .connecting: return Color.gray
        }
    }

    var buttonBorder: Color {
        switch self {
        case .connected: return Color(red: 0.875, green: 0.157, blue: 0.212)
        case .available: return .clear
        case .connecting: return Color.gray.opacity(0.3)
        }
    }

    var buttonBorderWidth: CGFloat {
        switch self {
        case .connected: return 1.5
        case .available: return 0
        case .connecting: return 1
        }
    }
}

// MARK: - View Model
@MainActor
class DeviceControllerViewModel: ObservableObject {
    @Published private(set) var connectedDevices: [DeviceInfo] = []
    @Published private(set) var availableDevices: [DeviceInfo] = []
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var connectingToPeer: MCPeerID? = nil

    private var mcManager: MCManager
    private var cancellables = Set<AnyCancellable>()
    private var scanTimer: Timer?

    init(mcManager: MCManager) {
        self.mcManager = mcManager
        setupBindings()
        refreshDevices()
    }

    private func setupBindings() {
        // Monitor discovered peers
        mcManager.$discoveredPeers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
            .store(in: &cancellables)

        // Monitor connection state
        mcManager.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

        // Monitor connected peer
        mcManager.$connectedPeer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: MCSessionState) {
        if state != .connecting {
            connectingToPeer = nil
        }
        refreshDevices()
    }

    private func refreshDevices() {
        // Get connected device
        if let connectedPeer = mcManager.connectedPeer {
            connectedDevices = [createDeviceInfo(from: connectedPeer, isConnected: true)]
        } else {
            connectedDevices = []
        }

        // Get available devices (excluding connected one)
        availableDevices = mcManager.discoveredPeers
            .filter { peer in
                peer != mcManager.connectedPeer
            }
            .map { peer in
                createDeviceInfo(from: peer, isConnected: false)
            }
    }

    private func createDeviceInfo(from peerID: MCPeerID, isConnected: Bool) -> DeviceInfo {
        let name = peerID.displayName
        let kind = detectDeviceKind(from: name)

        return DeviceInfo(
            id: peerID.displayName,
            peerID: peerID,
            name: name,
            kind: kind,
            isConnected: isConnected
        )
    }

    private func detectDeviceKind(from name: String) -> DeviceInfo.Kind {
        let lowercased = name.lowercased()

        if lowercased.contains("macbook") || lowercased.contains("laptop") {
            return .laptop
        } else if lowercased.contains("imac") || lowercased.contains("mac") || lowercased.contains("desktop") {
            return .desktop
        } else if lowercased.contains("iphone") || lowercased.contains("ipad") {
            return .phone
        }

        return .unknown
    }

    // MARK: - Public Actions

    func scanForDevices() {
        isScanning = true

        // Clear discovered peers and start fresh
        mcManager.forgetDiscoveredPeers()

        // Start browsing
        mcManager.startBrowsingIfNeeded()

        // Stop scanning after 5 seconds
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isScanning = false
            }
        }
    }

    func connect(to device: DeviceInfo) {
        guard !device.isConnected else { return }
        connectingToPeer = device.peerID
        mcManager.connect(to: device.peerID)
    }

    func disconnect(from device: DeviceInfo) {
        guard device.isConnected else { return }
        mcManager.userRequestedDisconnect()
        refreshDevices()
    }

    func toggleConnection(for device: DeviceInfo) {
        if device.isConnected {
            disconnect(from: device)
        } else {
            connect(to: device)
        }
    }

    func startBrowsing() {
        // Start browsing for devices
        mcManager.startBrowsingIfNeeded()
    }

    func stopBrowsing() {
        // Stop browsing to save battery
        mcManager.stopBrowsing()
    }
}