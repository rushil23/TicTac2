//
//  ViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class ConnectionViewController: UIViewController {
    
    //MARK: Variable Declaration
    //ConnectionService manages the phone-to-phone communication
    let connectionService = ConnectionService.sharedManager
    //Game Manager handles the game logic
    let game = GameManager.sharedManager
    
    // UI Outlets
    @IBOutlet weak var connectionSwitch: UISwitch!
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    //Go Live switch toggle
    @IBAction func goLiveSwitchToggled(_ sender: UISwitch) {
        let isOn =  connectionSwitch.isOn
        playButton.isEnabled = isOn //Enable/Disable playButton accordingly
        if (isOn) {
            connectionService.goLive()
        } else {
            connectionService.goOffline()
        }
        
    }
    
    //Button to start game
    @IBAction func playTapped(_ sender: UIButton) {
        let numConnections = connectionService.session.connectedPeers.count
        if (numConnections > 1) { //Multiple connections is currently not handled
            let alert = UIAlertController(title: "Error!", message: "Your device is connected to multiple devices. Reduce connections to exactly 1, and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok :o", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if (numConnections == 0){ //No devices found to connect with
            let alert = UIAlertController(title: "Error!", message: "No connected devices found. Turn WiFi/Bluetooth on to connect to other devices.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay :(", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            //Start game and send messages accordingly
            print("Play tapped")
            game.master = true //The master is the one who clicks play first.
            let message = "slave" //The other phone is now the slave
            connectionService.send(data: message)
            goToGameScreen()
        }
    }
    
    //Segue into the game screen
    func goToGameScreen(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let gameVC = storyBoard.instantiateViewController(withIdentifier: "GameView") as! GameViewController
        self.present(gameVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectionService.connectionDelegate = self
        
        //Initially disable connections and play button
        connectionSwitch.isOn = false
        playButton.isEnabled = false
        connectionService.goOffline()
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        self.connectionsLabel.textColor = ColorScheme.red
        
        //Hide connected device list : Remove this for testing purposes
        deviceName.isHidden = true
    }
    
    // Function to update connections
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
            self.game.master = false //You are the slave as you got the "slave" message
            self.goToGameScreen() //Go to game screen
        }
    }
    
    func connectedDevicesChanged(manager: ConnectionService, connectedDevices: [String]) {
        refreshData(connectedDevices) //Update connections UI
    }
    
}
