//
//  PlayService.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 6/1/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ConnectionServiceDelegate { //Functions called when connections change / during game initialization
    func connectedDevicesChanged(manager : ConnectionService, connectedDevices: [String])
    func playTapReceived(manager : ConnectionService, message: String)
}

protocol GamePlayDelegate { //Functions called during game play
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
    private let PlayServiceType = "tictac2-ios"
    
    //Connection Parameters
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    lazy var session : MCSession = { //Initialize connection session
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    override init() { //Initialize advertiser and browser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: PlayServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: PlayServiceType)
        
        super.init()
        
        goOffline() //Stay offline upon initialization
    }
    
    public func goLive() { //Start advertising and browing for peers
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    public func goOffline() { //Stop advertising and browsing for peers
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
        self.session.disconnect()
    }
    
    deinit {
        goOffline()
    }
    
    //Send data to peers
    func send(data: String) {
        print("MultipeerConnectivity: Sent: \(data) to \(session.connectedPeers.count) peers")
        
        let count = session.connectedPeers.count
        if (count>1) {
            print("DeveloperWarning: Multiple peers found.")
        }
        if count > 0 {
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
        print("MultipeerConnectivity: didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("MultipeerConnectivity: didReceiveInvitationFromPeer \(peerID)")
        
        //Accept invitation by default
        invitationHandler(true, self.session)
    }
    
}

extension ConnectionService : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("MultipeerConnectivity: didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("MultipeerConnectivity: foundPeer: \(peerID)")
        
        //Invite any peer that you find by default
        print("MultipeerConnectivity: invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        
        //Update connection status
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("MultipeerConnectivity: lostPeer: \(peerID)")
        
        //Update connection status / display toast message for disconnected state
        self.gamePlayDelegate?.disconnectReceived(manager: self)
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
}

extension ConnectionService : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("MultipeerConnectivity: peer \(peerID) didChangeState: \(state.rawValue)")
        
        //Update connection status
        self.connectionDelegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})

        switch state{
        case MCSessionState.connected:
            print("MultipeerConnectivity: Connected: \(peerID.displayName)")
            break
            
        case MCSessionState.connecting:
            print("MultipeerConnectivity: Connecting: \(peerID.displayName)")
            break
            
        case MCSessionState.notConnected:
            print("MultipeerConnectivity: Not Connected: \(peerID.displayName)")
            break
        }
    }
    
    //Message Received
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("MultipeerConnectivity: didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        print("Message Received = \(str)")
        if (str == "slave") { //This means that you are a slave, show next game screen
            self.connectionDelegate?.playTapReceived(manager: self, message: str)
        } else { //GameViewController handles any other messages.
            self.gamePlayDelegate?.gamePlayReceived(manager: self, message: str)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("MultipeerConnectivity: didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("MultipeerConnectivity: didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("MultipeerConnectivity: didFinishReceivingResourceWithName")
    }
}
