//
//  MCManager.swift
//  Controlio
//
//  Networking transport built on Apple's Network framework (Bonjour + TCP)
//  to replace the previous MultipeerConnectivity implementation.
//

import Foundation
import Network
#if os(iOS)
import UIKit
#endif

/// Minimal session states mirroring the original MultipeerConnectivity values.
enum MCSessionState: Int {
    case notConnected = 0
    case connecting = 1
    case connected = 2
}

/// Lightweight peer representation for Bonjour discovery.
struct MCPeerID: Identifiable, Hashable {
    let id: String
    let displayName: String
    let endpoint: NWEndpoint?

    init(displayName: String, endpoint: NWEndpoint? = nil) {
        self.displayName = displayName
        self.endpoint = endpoint
        if let endpoint = endpoint {
            self.id = "\(displayName)-\(endpoint.debugDescription)"
        } else {
            self.id = displayName
        }
    }
}

/*
 wrapper for iOS to macOS
 receiver calls startAdvertising()
 controller calls startBrowsing()
 */
final class MCManager: NSObject, ObservableObject {

    // called when chunk of bytes arrives
    var onEvents: (([Event]) -> Void)?

    // connection state changes
    var onStateChange: ((MCSessionState) -> Void)?

    var onDebug: ((String) -> Void)?

    @Published private(set) var sessionState: MCSessionState = .notConnected
    @Published private(set) var connectedPeer: MCPeerID? = nil
    @Published private(set) var discoveredPeers: [MCPeerID] = []

    @Published private(set) var lastConnectedPeer: MCPeerID? = nil
    @Published private(set) var manuallyDisconnected: Bool = false
    private var requestedPeerName: String? = nil

    var connectedDeviceName: String? { connectedPeer?.displayName }

    func connect(to peer: MCPeerID, timeout: TimeInterval = 10) {
        _ = timeout // preserved for API compatibility
        requestedPeerName = peer.displayName
        guard let endpoint = peer.endpoint else {
            log("[NW] connect(to:) missing endpoint for \(peer.displayName)")
            return
        }
        startConnection(to: endpoint, peer: peer)
    }

    func forgetDiscoveredPeers() {
        discoveredPeers.removeAll()
    }

    func availableReceivers() -> [MCPeerID] { discoveredPeers }

    var currentState: MCSessionState { sessionState }

    private(set) var suppressAutoRetry = false
    private var hasStartedBrowsing = false

    func startBrowsingIfNeeded() {
        guard !suppressAutoRetry, !hasStartedBrowsing else { return }
        hasStartedBrowsing = true
        startBrowsing()
    }
    
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        hasStartedBrowsing = false
    }
    
    func userRequestedDisconnect() {
        suppressAutoRetry = true
        manuallyDisconnected = true
        requestedPeerName = nil
        stopBrowsing()
        if let cp = connectedPeer { lastConnectedPeer = cp }
        connectedPeer = nil
        connection?.cancel()
        sessionState = .notConnected
        onStateChange?(.notConnected)
    }
    
    func userRequestedReconnect() {
        suppressAutoRetry = false
        startBrowsingIfNeeded()
    }
    
    func disconnect(keepRetrying: Bool = true) {
        connection?.cancel()
        connection = nil
        sessionState = .notConnected
        onStateChange?(.notConnected)
        if keepRetrying { startBrowsingIfNeeded() }
    }
    
    private func log(_ s: String) {
        print(s)
        onDebug?(s)
    }
    
    private func autoReconnectIfNeeded(for peer: MCPeerID) {
        guard !suppressAutoRetry else { return }

        guard connectedPeer == nil else { return }

        if let target = requestedPeerName {
            guard target == peer.displayName else { return }
        } else {
            guard let lastName = lastKnownDeviceName,
                  lastName == peer.displayName,
                  knownDeviceNames.contains(lastName) else {
                return
            }
        }

        connect(to: peer)
    }
    
    // Network state
    static let serviceType = "_controlio-trk._tcp"
    private let queue = DispatchQueue(label: "controlio.network", qos: .userInitiated)
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?

    private let knownDevicesDefaultsKey = "mc.knownDevices"
    private let lastDeviceDefaultsKey  = "mc.lastDeviceName"
    
    var knownDeviceNames: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: knownDevicesDefaultsKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: knownDevicesDefaultsKey)
        }
    }
    
    var lastKnownDeviceName: String? {
        get {
            UserDefaults.standard.string(forKey: lastDeviceDefaultsKey)
        }
        set {
            let defaults = UserDefaults.standard
            if let value = newValue {
                defaults.set(value, forKey: lastDeviceDefaultsKey)
            } else {
                defaults.removeObject(forKey: lastDeviceDefaultsKey)
            }
        }
    }
    
    private func rememberConnectedPeer(_ peer: MCPeerID) {
        let name = peer.displayName

        // Add to knownDevices if not already present
        var known = knownDeviceNames
        if !known.contains(name) {
            known.append(name)
            knownDeviceNames = known
        }

        // Update last-used device
        lastKnownDeviceName = name
    }
    
    func forgetDevice(named name: String) {
        // Remove from known list
        var known = knownDeviceNames
        known.removeAll { $0 == name }
        knownDeviceNames = known

        if lastKnownDeviceName == name {
            lastKnownDeviceName = nil
        }

        if requestedPeerName == name {
            requestedPeerName = nil
        }

        if connectedPeer?.displayName == name {
            userRequestedDisconnect()
        }
    }

    private let localPeer: MCPeerID = {
        #if os(iOS)
        return MCPeerID(displayName: UIDevice.current.name)
        #elseif os(macOS)
        let name = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        return MCPeerID(displayName: name)
        #else
        return MCPeerID(displayName: "Controlio")
        #endif
    }()
    
    override init() {
        super.init()
    }
    
    // make receiver visible and auto-accept connections
    func startAdvertising() {
        stop()
        do {
            let params = NWParameters.tcp
            params.includePeerToPeer = true
            let listener = try NWListener(using: params)
            listener.service = NWListener.Service(name: localPeer.displayName, type: Self.serviceType)
            listener.stateUpdateHandler = { [weak self] state in
                self?.log("[NW] listener state: \(state)")
            }
            listener.newConnectionHandler = { [weak self] newConnection in
                self?.handleIncoming(connection: newConnection)
            }
            listener.start(queue: queue)
            self.listener = listener
            log("[NW] Advertising as \(localPeer.displayName)")
        } catch {
            log("[NW] Failed to start listener: \(error.localizedDescription)")
        }
    }
    
    private func handleIncoming(connection newConnection: NWConnection) {
        let peer = MCPeerID(displayName: peerName(from: newConnection.endpoint), endpoint: newConnection.endpoint)
        connection?.cancel()
        connection = newConnection
        DispatchQueue.main.async {
            self.sessionState = .connecting
            self.onStateChange?(.connecting)
        }
        newConnection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state, peer: peer)
        }
        startReceive(on: newConnection, peer: peer)
        newConnection.start(queue: queue)
    }
    
    // search for receiver and auto-invite
    func startBrowsing() {
        browser?.cancel()
        let descriptor = NWBrowser.Descriptor.bonjour(type: Self.serviceType, domain: nil)
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let browser = NWBrowser(for: descriptor, using: params)
        browser.stateUpdateHandler = { [weak self] state in
            self?.log("[NW] browser state: \(state)")
        }
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self = self else { return }
            let peers = results.compactMap { self.makePeer(from: $0) }
            DispatchQueue.main.async {
                self.discoveredPeers = peers
            }
            peers.forEach { self.autoReconnectIfNeeded(for: $0) }
        }
        browser.start(queue: queue)
        self.browser = browser
    }
    
    func stop() {
        listener?.cancel()
        browser?.cancel()
        connection?.cancel()
        listener = nil
        browser = nil
        connection = nil
        sessionState = .notConnected
        hasStartedBrowsing = false
    }
    
    // send single event object as json
    func send(_ event: Event, reliable: Bool = true) {
        let data = encodeLine(event)
        if data.isEmpty {
            log("[send] encode empty")
            return
        }
        sendRaw(data, reliable: reliable)
    }
    
    // send bytes
    func sendRaw(_ data: Data, reliable: Bool = true) {
        guard let conn = connection else {
            log("[send] no connection")
            return
        }
        conn.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.log("[send] error: \(error.localizedDescription)")
            }
        })
    }
    
    // connection status
    var isConnected: Bool { sessionState == .connected }

    private func startConnection(to endpoint: NWEndpoint, peer: MCPeerID) {
        connection?.cancel()
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let conn = NWConnection(to: endpoint, using: params)
        connection = conn
        DispatchQueue.main.async {
            self.sessionState = .connecting
            self.onStateChange?(.connecting)
        }
        conn.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state, peer: peer)
        }
        startReceive(on: conn, peer: peer)
        conn.start(queue: queue)
    }

    private func handleConnectionState(_ state: NWConnection.State, peer: MCPeerID) {
        switch state {
        case .ready:
            DispatchQueue.main.async {
                self.connectedPeer = peer
                self.lastConnectedPeer = peer
                self.manuallyDisconnected = false
                self.requestedPeerName = nil
                self.sessionState = .connected
                self.onStateChange?(.connected)
                self.rememberConnectedPeer(peer)
            }
        case .failed(let error):
            log("[NW] connection failed: \(error.localizedDescription)")
            fallthrough
        case .cancelled:
            DispatchQueue.main.async {
                self.connectedPeer = nil
                self.sessionState = .notConnected
                self.onStateChange?(.notConnected)
                if !self.suppressAutoRetry { self.startBrowsingIfNeeded() }
            }
        case .waiting(let error):
            log("[NW] connection waiting: \(error.localizedDescription)")
        case .preparing, .setup:
            break
        @unknown default:
            break
        }
    }

    private func startReceive(on connection: NWConnection, peer: MCPeerID) {
        _ = peer
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                let events = decodeLines(data)
                if !events.isEmpty { self.onEvents?(events) }
            }

            if isComplete || error != nil {
                self.log("[NW] receive finished (error: \(error?.localizedDescription ?? "none"))")
                connection.cancel()
                DispatchQueue.main.async {
                    self.connectedPeer = nil
                    self.sessionState = .notConnected
                    self.onStateChange?(.notConnected)
                    if !self.suppressAutoRetry { self.startBrowsingIfNeeded() }
                }
                return
            }

            self.startReceive(on: connection, peer: peer)
        }
    }

    private func makePeer(from result: NWBrowser.Result) -> MCPeerID? {
        let endpoint = result.endpoint
        let name = peerName(from: endpoint)
        return MCPeerID(displayName: name, endpoint: endpoint)
    }

    private func peerName(from endpoint: NWEndpoint) -> String {
        switch endpoint {
        case let .service(name: name, type: _, domain: _, interface: _):
            return name
        case let .hostPort(host, _):
            return host.debugDescription
        default:
            return endpoint.debugDescription
        }
    }
}
