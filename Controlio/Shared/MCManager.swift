//
//  MCManager.swift
//  Controlio
//
//  Created by Avis Luong on 10/16/25.
//

import Foundation
import MultipeerConnectivity

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
    
    // MC state
    private let serviceType = "controlio-trk"
    private let peerID = MCPeerID(displayName: Host.current().localizedName)
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
        sendRaw(encodeLine(event))
    }
    
    // send bytes
    func sendRaw(_ data: Data) {
        let peers = session.connectedPeers
        guard !peers.isEmpty else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }
    
    // connection status
    var isConnected: Bool { !session.connectedPeers.isEmpty }
}

// delegate for connection state and incoming data
extension MCManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        onStateChange?(state)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let events = decodeLines(data)
        if !events.isEmpty { onEvents?(events) }
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
        invitationHandler(true, session)
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
}
