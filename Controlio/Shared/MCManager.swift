//
//  MCManager.swift
//  Controlio
//
//  Created by Avis Luong on 10/16/25.
//

import Foundation
import MultipeerConnectivity
#if os(iOS)
import UIKit
#endif
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
    
    var connectedDeviceName: String? { connectedPeer?.displayName }
    
    func connect(to peer: MCPeerID, timeout: TimeInterval = 10) {
        guard browser != nil else {
            log("[MC] connect(to:) requires an active browser; call userRequestedReconnect() first.")
            return
        }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: timeout)
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
        browser?.stopBrowsingForPeers()
        browser = nil
        hasStartedBrowsing = false
    }
    
    func userRequestedDisconnect() {
        suppressAutoRetry = true
        manuallyDisconnected = true
        stopBrowsing()
        if let cp = connectedPeer { lastConnectedPeer = cp }
        connectedPeer = nil
        session.disconnect()
        sessionState = .notConnected
        onStateChange?(.notConnected)
    }
    
    func userRequestedReconnect() {
        suppressAutoRetry = false
        startBrowsingIfNeeded()
    }
    
    func disconnect(keepRetrying: Bool = true) {
        session.disconnect()
        if keepRetrying { startBrowsingIfNeeded() }
    }
    
    private func log(_ s: String) {
        print(s)
        onDebug?(s)
    }
    
    private func autoReconnectIfNeeded(for peer: MCPeerID) {
        guard !suppressAutoRetry else { return }

        guard connectedPeer == nil else { return }

        guard let lastName = lastKnownDeviceName,
              lastName == peer.displayName,
              knownDeviceNames.contains(lastName) else {
            return
        }

        connect(to: peer)
    }
    
    // MC state
    private let serviceType = "controlio-trk"
    private let peerID: MCPeerID = {
        #if os(iOS)
        return MCPeerID(displayName: UIDevice.current.name)
        #elseif os(macOS)
        // fall back to hostName if needed
        let name = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        return MCPeerID(displayName: name)
        #else
        return MCPeerID(displayName: "Controlio")
        #endif
    }()
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
        
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

        if connectedPeer?.displayName == name {
            userRequestedDisconnect()
        }
    }

    override init() {
        super.init()
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    // make receiver visisble and auto-accept conns
    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    // search for receiver and auto-invite
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        session.disconnect()
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
        let peers = session.connectedPeers
        guard !peers.isEmpty else {
            log("[send] no peers")
            return
        }
        do {
            try session.send(data, toPeers: peers, with: reliable ? .reliable : .unreliable)
        } catch {
            log("[send] error: \(error.localizedDescription)")
        }
    }
    
    // connection status
    var isConnected: Bool { !session.connectedPeers.isEmpty }
}

// delegate for connection state and incoming data
extension MCManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log("[MC] \(peerID.displayName) state: \(state.rawValue)")
        DispatchQueue.main.async {
            self.onStateChange?(state)
            self.sessionState = state
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.lastConnectedPeer = peerID
                self.manuallyDisconnected = false
                self.rememberConnectedPeer(peerID)
            case .notConnected:
                if let any = session.connectedPeers.first {
                    self.connectedPeer = any
                } else {
                    self.connectedPeer = nil
                }
                // only auto-retry if not a manual disconnect
                if !self.suppressAutoRetry { self.startBrowsingIfNeeded() }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let events = decodeLines(data)
        if !events.isEmpty { onEvents?(events) }
//        log("[MC] didReceive \(events.count) event(s) from \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didReceive certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        log("[MC] certificate from \(peerID.displayName) - accepting")
        certificateHandler(true)
    }
    // empty stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// delegate for advertiser/browser
extension MCManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log("[macOS] Invitation from: \(peerID.displayName)")
        invitationHandler(true, session)
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        print("[iOS] foundPeer:", peerID.displayName)
        if !discoveredPeers.contains(where: { $0 == peerID }) {
            DispatchQueue.main.async { self.discoveredPeers.append(peerID) }
        }
        autoReconnectIfNeeded(for: peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.discoveredPeers.removeAll { $0 == peerID } }
    }
}
