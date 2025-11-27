//
//  DeviceControllerViewModel.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/19/25.
//

import SwiftUI
import Combine

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
    let isReachable: Bool
    let isConnecting: Bool

    var subtitle: String {
        switch kind {
        case .laptop: return "Laptop"
        case .desktop: return "Desktop"
        case .phone: return "Phone"
        case .unknown: return "Device"
        }
    }

    var connectionStatus: DeviceConnectionStatus {
        if isConnected {
            return .connected
        }
        if isConnecting {
            return .connecting
        }
        if !isReachable {
            return .offline
        }
        return .available
    }
}

enum DeviceConnectionStatus {
    case connected
    case available
    case connecting
    case offline

    var displayName: String {
        switch self {
        case .connected: return "connected"
        case .available: return "available"
        case .connecting: return "connecting..."
        case .offline: return "offline"
        }
    }

    var badgeBackground: Color {
        switch self {
        case .connected: return Color(red: 1.0, green: 0.894, blue: 0.839)
        case .available: return Color(red: 0.862, green: 0.957, blue: 0.882)
        case .connecting: return Color.gray.opacity(0.2)
        case .offline: return Color.black.opacity(0.06)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .connected: return Color(red: 1.0, green: 0.451, blue: 0.216)
        case .available: return Color(red: 0.129, green: 0.549, blue: 0.184)
        case .connecting: return Color.gray
        case .offline: return Color.gray
        }
    }

    var actionTitle: String {
        switch self {
        case .connected: return "Disconnect"
        case .available: return "Connect"
        case .connecting: return "Connecting..."
        case .offline: return "Offline"
        }
    }

    var buttonBackground: Color {
        switch self {
        case .connected: return .white
        case .available: return Color(red: 1.0, green: 0.451, blue: 0.216)
        case .connecting: return Color.gray.opacity(0.2)
        case .offline: return Color.clear
        }
    }

    var buttonForeground: Color {
        switch self {
        case .connected: return Color(red: 0.875, green: 0.157, blue: 0.212)
        case .available: return .white
        case .connecting: return Color.gray
        case .offline: return Color.gray
        }
    }

    var buttonBorder: Color {
        switch self {
        case .connected: return Color(red: 0.875, green: 0.157, blue: 0.212)
        case .available: return .clear
        case .connecting: return Color.gray.opacity(0.3)
        case .offline: return Color.black.opacity(0.08)
        }
    }

    var buttonBorderWidth: CGFloat {
        switch self {
        case .connected: return 1.5
        case .available: return 0
        case .connecting: return 1
        case .offline: return 1
        }
    }

    var isActionEnabled: Bool {
        switch self {
        case .connecting, .offline:
            return false
        case .connected, .available:
            return true
        }
    }
}

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
        let connectedPeer = mcManager.connectedPeer
        let discoveredPeers = mcManager.discoveredPeers
        let knownNames = mcManager.knownDeviceNames
        let connectingName = connectingToPeer?.displayName
        
        var connected: [DeviceInfo] = []
        var available: [DeviceInfo] = []
        
        for peer in discoveredPeers {
            let isConnected = (peer == connectedPeer)
            let isConnecting = (connectingToPeer == peer)

            let info = createDeviceInfo(
                from: peer,
                isConnected: isConnected,
                isReachable: true,
                isConnecting: isConnecting
            )

            if isConnected {
                connected.append(info)
            } else {
                available.append(info)
            }
        }
        for name in knownNames {
            guard !discoveredPeers.contains(where: { $0.displayName == name }) else { continue }

            let kind = detectDeviceKind(from: name)
            let stubPeer = MCPeerID(displayName: name)
            
            let isTarget = (connectingName == name)

            let info = DeviceInfo(
                id: name,
                peerID: stubPeer,
                name: name,
                kind: kind,
                isConnected: false,
                isReachable: isTarget,
                isConnecting: isTarget
            )

            available.append(info)
        }

        connectedDevices = connected
        availableDevices = available
    }

    private func createDeviceInfo(from peerID: MCPeerID, isConnected: Bool, isReachable: Bool, isConnecting: Bool) -> DeviceInfo {
        let name = peerID.displayName
        let kind = detectDeviceKind(from: name)

        return DeviceInfo(
            id: name,
            peerID: peerID,
            name: name,
            kind: kind,
            isConnected: isConnected,
            isReachable: isReachable,
            isConnecting: isConnecting
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

    func scanForDevices() {
        isScanning = true

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
    
    func forget(_ device: DeviceInfo) {
        mcManager.forgetDevice(named: device.name)
        refreshDevices()
    }

    func connect(to device: DeviceInfo) {
        guard !device.isConnected else { return }

        connectingToPeer = device.peerID

        refreshDevices()
        mcManager.userRequestedReconnect()
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
