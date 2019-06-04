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
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        self.connectionsLabel.textColor = ColorScheme.red
        
        //Setup Error Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(connectionErrorOccured), name: .randomErrorOccured, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectErrorOccured), name: .disconnectErrorOccured, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        //Initially disable connections and play button
        connectionSwitch.setOn(false, animated: true)
        playButton.isEnabled = false
        connectionService.goOffline()
        
        //Reset Game Parameters - Necessary to set master to Nil once we are back to connection screen.
        game.resetGameParameters()
        
    }
    
    @objc func connectionErrorOccured() {
        let alert = UIAlertController(title: "Oops!", message: "Something went wrong with the connection. Please try again!", preferredStyle: .alert)
        //Ideally the handler here will send a READY message
        alert.addAction(UIAlertAction(title: "Okay :/", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func disconnectErrorOccured() {
        let alert = UIAlertController(title: "Oops!", message: "Looks like your friend has disconnected. Please try connecting again.", preferredStyle: .alert)
        //Ideally the handler here will send a READY message
        alert.addAction(UIAlertAction(title: "Ouch :/", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Function to update connections count
    func refreshData() {
        DispatchQueue.main.async {
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
        refreshData() //Update connections UI
    }
    
}

extension Notification.Name {
    static let randomErrorOccured = Notification.Name("randomErrorOccured")
    static let disconnectErrorOccured = Notification.Name("disconnectErrorOccured")
}
