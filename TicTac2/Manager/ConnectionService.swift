//
//  PlayService.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 6/1/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ConnectionServiceDelegate { //Implementation in view controller to update UI
    func connectedDevicesChanged(manager : ConnectionService, connectedDevices: [String])
    func playTapReceived(manager : ConnectionService, message: String)
}

protocol GamePlayDelegate {
    func gamePlayReceived(manager: ConnectionService, message: String)
    func disconnectReceived(manager: ConnectionService)
}

class ConnectionService: NSObject {
    
    //Singleton Declaration
    static let sharedManager = ConnectionService()
    
    var connectionDelegate : ConnectionServiceDelegate?
    var gamePlayDelegate: GamePlayDelegate?
    
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let PlayServiceType = "tictac2-ios" //Future Improvement: Let users enter room ID to allow private connections
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    lazy var session : MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self as MCSessionDelegate
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: PlayServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: PlayServiceType)
        
        super.init()
        
        goOffline()
    }
    
    public func goLive() {
        self.serviceAdvertiser.delegate = self as MCNearbyServiceAdvertiserDelegate
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self as MCNearbyServiceBrowserDelegate
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    public func goOffline() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
        self.session.disconnect()
    }
    
    deinit {
        goOffline()
    }
    
    func send(data: String) {
        print("MultipeerConnectivity: Sent: \(data) to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(data.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                print("MultipeerConnectivity: Error for sending: \(error)")
            }
        }
        
    }
}

extension ConnectionService : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
}

extension ConnectionService : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        print("invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
        
        self.gamePlayDelegate?.disconnectReceived(manager: self)
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
}

extension ConnectionService : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        
        
        switch state{
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            break
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            break
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        print("Message Received = \(str)")
        if (str == "slave") {
            self.connectionDelegate?.playTapReceived(manager: self, message: str)
        } else {
            self.gamePlayDelegate?.gamePlayReceived(manager: self, message: str)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
}