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

final class MCManager: NSObject {
    
    // called when chunk of bytes arrives
    var onEvents: (([Event]) -> Void)?
    
    // connection state changes
    var onStateChange: ((MCSessionState) -> Void)?
    
    var onDebug: ((String) -> Void)?
    
    private func log(_ s: String) {
        print(s)
        onDebug?(s)
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
    func send(_ event: Event) {
        let data = encodeLine(event)
        if data.isEmpty {
            log("[send] encode empty")
            return
        }
        sendRaw(data)
    }
    
    // send bytes
    func sendRaw(_ data: Data) {
        let peers = session.connectedPeers
        guard !peers.isEmpty else {
            log("[send] no peers")
            return
        }
        do {
            try session.send(data, toPeers: peers, with: .reliable)
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
        DispatchQueue.main.async { self.onStateChange?(state) }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let events = decodeLines(data)
        if !events.isEmpty { onEvents?(events) }
        log("[MC] didReceive \(events.count) event(s) from \(peerID.displayName)")
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
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
}
