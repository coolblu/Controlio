//
//  DeviceControllerViewModel.swift
//  Controlio
//
//  Created by Masayuki Yamazaki on 11/19/25.
//

import SwiftUI
import MultipeerConnectivity
import Combine

struct DeviceInfo: Identifiable {
    enum Kind {
        case laptop
        case desktop
        case mac

        var iconName: String {
            switch self {
            case .laptop: return "laptopcomputer"
            case .desktop: return "desktopcomputer"
            case .mac: return "desktopcomputer"
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
        case .mac: return "Mac"
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
        mcManager.$discoveredPeers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDevices()
            }
            .store(in: &cancellables)

        mcManager.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)

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
        let connectedName = connectedPeer?.displayName
        let connectingName = connectingToPeer?.displayName

        var devicesByName: [String: DeviceInfo] = [:]

        func upsert(_ info: DeviceInfo) {
            if let existing = devicesByName[info.name] {
                if devicePriority(info) > devicePriority(existing) {
                    devicesByName[info.name] = info
                }
            } else {
                devicesByName[info.name] = info
            }
        }
        
        for peer in mcManager.discoveredPeers {
            let name = peer.displayName
            
            guard isValidDeviceName(name) else { continue }
            
            let isConnected = (peer == connectedPeer) || (name == connectedName)
            let isConnecting = (connectingToPeer == peer) || (name == connectingName)

            let info = createDeviceInfo(
                from: peer,
                isConnected: isConnected,
                isReachable: true,
                isConnecting: isConnecting
            )

            upsert(info)
        }

        if let connectedPeer, devicesByName[connectedPeer.displayName] == nil {
            let info = createDeviceInfo(
                from: connectedPeer,
                isConnected: true,
                isReachable: true,
                isConnecting: false
            )

            upsert(info)
        }

        for name in mcManager.knownDeviceNames {
            guard isValidDeviceName(name) else { continue }
            guard devicesByName[name] == nil else { continue }

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

            upsert(info)
        }

        let devices = Array(devicesByName.values)
        connectedDevices = devices
            .filter { $0.isConnected }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        availableDevices = devices
            .filter { !$0.isConnected }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func devicePriority(_ info: DeviceInfo) -> Int {
        if info.isConnected { return 3 }
        if info.isConnecting { return 2 }
        if info.isReachable { return 1 }
        return 0
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
        } else if lowercased.contains("imac") || lowercased.contains("desktop") {
            return .desktop
        }
        
        return .mac
    }
    
    private func isValidDeviceName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    func scanForDevices() {
        isScanning = true

        // Start browsing
        mcManager.startBrowsingIfNeeded()

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
        mcManager.startBrowsingIfNeeded()
    }
}
