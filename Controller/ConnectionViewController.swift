//
//  ViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {
    
    let connectionService = ConnectionService.sharedManager
    
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    
    let game = GameManager.sharedManager
    
    @IBAction func goLiveSwitchToggled(_ sender: UISwitch) {
        
        let isOn = sender.isOn == true
        
        if (isOn) {
            connectionService.goLive()
        } else {
            connectionService.goOffline()
        }
        
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        print("Play tapped")
        let message = "slave"
        game.master = true
        connectionService.send(data: message)
        goToGameScreen()
    }
    
    
    func goToGameScreen(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let gameVC = storyBoard.instantiateViewController(withIdentifier: "GameView") as! GameViewController
        self.present(gameVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connectionService.connectionDelegate = self
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        
    }
    
    func refreshData(_ connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.deviceName.text = "\(connectedDevices)"
            self.connectionsLabel.text = "Connections: \(self.connectionService.session.connectedPeers.count) Device(s) Connected!"
        }
    }

}

extension ConnectionViewController : ConnectionServiceDelegate {
    func playTapReceived(manager: ConnectionService, message: String) {
        DispatchQueue.main.async {
            if (message == "slave") {
                print("Received Message: \(message)")
                self.game.master = false
                self.goToGameScreen()
            } else if (message == "master") {
                self.game.initializeGame()
            }
        }
    }
    
    func connectedDevicesChanged(manager: ConnectionService, connectedDevices: [String]) {
        refreshData(connectedDevices)
    }
    
}
