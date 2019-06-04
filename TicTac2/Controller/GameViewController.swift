//
//  GameViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //MARK: Variable Declaration
    //UI Outlets
    @IBOutlet weak var currentPlayerImage: UIImageView!
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var yourTurnLabel: UILabel!
    @IBOutlet weak var currentPlayerStack: UIStackView!
    
    //Connection Service manages the phone-to-phone communication
    let connectionService = ConnectionService.sharedManager
    //Game Manager manages the game logic
    var game = GameManager.sharedManager
    
    //UI Constants
    let animationDuration = 0.2
    let X = UIImage(named: "crossred.png")
    let O = UIImage(named: "redcircle.png")
    
    //MARK: Did Sets
    //True when it is your turn to play
    var yourTurn: Bool? { //Updates the label below the grid
        didSet {
            print("Your Turn = \(String(describing: yourTurn))")
            guard let yourTurn = yourTurn else {
                yourTurnLabel.isHidden = true
                return
            }
            yourTurnLabel.isHidden = false
            
            self.yourTurnLabel.text = "\(yourTurn ? "Your":"Their") Turn"
            self.yourTurnLabel.textColor = yourTurn ? ColorScheme.green : ColorScheme.red
            
        }
    }
    
    //True if you are player X for the game
    var playerX: Bool? { //Updates the image on top of the grid
        didSet {
            print("Is Player X? = \(String(describing: playerX))")
            guard let playerX = playerX else {
                currentPlayerStack.isHidden = true
                return
            }
            currentPlayerStack.isHidden = false
            currentPlayerImage.image = playerX ? X : O
            
        }
    }
    
    //MARK: Initializations
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        
        game.initializeGrid()
        
        //Slave notifies master once its done setting up
        connectionService.gamePlayDelegate = self
        let master = game.master ?? false
        if (!master) { //If you are the slave, notify the master
            connectionService.send(data: "master")
        }
    }
    
    //Initialize game parameters and decide who is X and O
    func initialize() {
        game.initializeGame()
        DispatchQueue.main.async {
            self.playerX = self.game.playerX
            self.yourTurn = self.game.yourTurn
            self.gridView.reloadData()
        }
        
    }
    
    
    @IBAction func goBackButtonPressed(_ sender: Any) {
        goToConnectionScreen()
    }
    
    //Segue to connection screen
    func goToConnectionScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Collection View Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return game.size * game.size
    }
    
    // Adjust number of rows & columns - by adjusting size of cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let space = 2 //Here 2 is the minimum spacing between cells
        let minSpacing = CGFloat(space * (game.size - 1))
        let size = CGFloat(game.size)
        
        return CGSize(width: (collectionView.bounds.size.width - minSpacing)/size,
                          height: (collectionView.bounds.size.height - minSpacing)/size)
    }
    
    // Handles Grid & Words UI - updates colors upon different user interactions
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let grid = gridView.dequeueReusableCell(withReuseIdentifier: "Grid", for: indexPath) as! GridView
        let index = indexPath.item
        
        let status = game.getStatusAt(index)
        
        grid.backgroundColor = ColorScheme.yellow

        switch(status){
            case .notSelected: //Hide image view initially
                grid.image.isHidden = true
                break
            case .playerX:
                grid.image.isHidden = false //Show X
                grid.image.image = UIImage(named: "crossred.png")
                break
            case .playerO:
                grid.image.isHidden = false //Show O
                grid.image.image = UIImage(named: "redcircle.png")
                break
        }
        
        return grid
        
    }
    
    // Lets users play X / O if it's their turn
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let yourTurn = yourTurn else {
            print("DeveloperWarning: yourTurn was found to be nil")
            return
        }
        if (yourTurn) { //Only let users play if its their turn
            didSelectAt(indexPath.item)
        }
    }
    
    func didSelectAt(_ index: Int) {
        //To prevent changing an already selected grid
        guard (game.getStatusAt(index) == .notSelected) else { return }
        
        self.yourTurn = false //Not your turn anymore
        game.selectedCount += 1
        
        //Sending this message will trigger the other person's turn to be True
        connectionService.send(data: "\(index)")
        
        let isX = game.playerX
        game.updateStatusAtIndex(status: (isX ? .playerX : .playerO), index: index)
    
        UIView.animate(withDuration: animationDuration, animations: {
            self.gridView.reloadItems(at: [IndexPath(item: index, section: 0)])
        })
        checkWinCase(index)
    }
    
    //Function to update changes from the other user
    func theySelectedAt(_ index: Int) {
        game.selectedCount += 1
        let isX = game.playerX
        game.updateStatusAtIndex(status: isX ? .playerO : .playerX, index: index)
        UIView.animate(withDuration: animationDuration, animations: {
            self.gridView.reloadItems(at: [IndexPath(item: index, section: 0)])
        })
        checkWinCase(index)
    }
    
    //Check if game has ended by the last tap at index
    func checkWinCase(_ index: Int) {
        let winStatus = game.hasUserWon(index)
        
        var title: String
        var message: String
        var action: String
        
        if (winStatus == .notYet) {
            if (game.selectedCount != 9) {
                return
            }
            title = "Game Tied!"
            message = "Looks like you both are equally good at this ;)"
            action = "Okay, i guess?"
        }  else {
            let won = winStatus == .won
            title = "You \((won ? "won":"lost"))!"
            message = won ? "You're good at this. Congrats!" : "You'll get better, don't worry :)"
            action = won ? "Great!" : "Ok :/"
        }
    
        //Show win alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: action, style: .default, handler: { action in
            self.endGame()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func endGame() {
        initialize()
    }
    
    //Check if game.master and the message we receive agree with each other
    //This is to handle the edge case that a master receives a "slave" message
    func checkMasterSlaveSetup(isMaster: Bool) -> Bool{
        guard let master = game.master else {
            randomErrorOccured()
            return false
        }
        if (master != isMaster) { //This means that the master/slave setup failed
            randomErrorOccured()
            return false
        }
        return true
    }
    
    func randomErrorOccured() {
        goToConnectionScreen()
        NotificationCenter.default.post(name: .randomErrorOccured, object: nil)
    }
}

// Handles communication from other phone
extension GameViewController : GamePlayDelegate {
    func gamePlayReceived(manager: ConnectionService, message: String) {
        print("Game Play Received = \(message)")
        
        // The "master" message is a sign that the slave has finished loading
        if (message == "master") { //Initialize game and set the image
            guard checkMasterSlaveSetup(isMaster: true) else { return }
            game.initializeGame()
            DispatchQueue.main.async {
                self.yourTurn = self.game.yourTurn
                self.playerX = self.game.playerX
            }
        // Handles game initialization and sets parameters
        // This is a message sent by the master to the slave
        } else if (message == "X" || message == "O") {
            guard checkMasterSlaveSetup(isMaster: false) else { return }
            game.playerX = (message == "X")
            game.yourTurn = game.playerX
            DispatchQueue.main.async {
                self.initialize()
            }
        // Handles index messages, to indicate which index the last turn was played at.
        } else {
            guard let index = Int(message) else { return }
            game.yourTurn = true
            DispatchQueue.main.async {
                self.yourTurn = true
                self.theySelectedAt(index)
            }
        }
        
    }
    
    //Disconnect occurs when the connection loses a peer
    func disconnectReceived(manager: ConnectionService) {
        print("Other device has disconnected. Connections remaining: \(connectionService.session.connectedPeers.count)")
        goToConnectionScreen()
        NotificationCenter.default.post(name: .disconnectErrorOccured, object: nil)
    }

}
