//
//  ViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {
    
    let playService = PlayService()
    
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    
    
    
    @IBAction func goLiveSwitchToggled(_ sender: UISwitch) {
        
        let isOn = sender.isOn == true
        
        if (isOn) {
            playService.goLive()
        } else {
            playService.goOffline()
        }
        
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        print("Play tapped")
        let text = UIDevice.current.name
        playService.send(songUri: text)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        playService.delegate = self
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        
    }
    
    func refreshData(_ connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.deviceName.text = "\(connectedDevices)"
            self.connectionsLabel.text = "Connections: \(self.playService.session.connectedPeers.count) Device(s) Connected!"
        }
    }


}

extension ConnectionViewController : PlayServiceDelegate {
    
    func connectedDevicesChanged(manager: PlayService, connectedDevices: [String]) {
        refreshData(connectedDevices)
    }
    
    func playTapReceived(manager: PlayService, songUri: String) {
        OperationQueue.main.addOperation {
            print("Received song name = \(songUri)")
            
        }
    }
    
}


