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
    
    @IBOutlet weak var connectionSwitch: UISwitch!
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    let game = GameManager.sharedManager
    
    @IBAction func goLiveSwitchToggled(_ sender: UISwitch) {
        
        let isOn =  connectionSwitch.isOn
        playButton.isEnabled = isOn
        if (isOn) {
            connectionService.goLive()
        } else {
            connectionService.goOffline()
        }
        
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        let numConnections = connectionService.session.connectedPeers.count
        
        if (numConnections > 1) {
            let alert = UIAlertController(title: "Error!", message: "Your device is connected to multiple devices. Reduce connections to exactly 1, and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok :o", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if (numConnections == 0){
            let alert = UIAlertController(title: "Error!", message: "No connected devices found. Turn WiFi/Bluetooth on to connect to other devices.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay :(", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            print("Play tapped")
            let message = "slave"
            game.master = true
            connectionService.send(data: message)
            goToGameScreen()
        }
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
        
        connectionSwitch.isOn = false
        playButton.isEnabled = false
        connectionService.goOffline()
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        self.connectionsLabel.textColor = ColorScheme.red
        
    }
    
    func refreshData(_ connectedDevices: [String]) {
        DispatchQueue.main.async {
            self.deviceName.text = "\(connectedDevices)"
            let numConnections = self.connectionService.session.connectedPeers.count
            self.connectionsLabel.textColor = (numConnections == 1) ? ColorScheme.green : ColorScheme.red
            self.connectionsLabel.text = "Connection(s): \(numConnections)"
        }
    }

}

extension ConnectionViewController : ConnectionServiceDelegate {
    func playTapReceived(manager: ConnectionService, message: String) {
        DispatchQueue.main.async {
            print("Received Message: \(message)")
            self.game.master = false
            self.goToGameScreen()
        }
    }
    
    func connectedDevicesChanged(manager: ConnectionService, connectedDevices: [String]) {
        refreshData(connectedDevices)
    }
    
}
