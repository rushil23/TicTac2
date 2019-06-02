//
//  GameViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var currentPlayerImage: UIImageView!
    @IBOutlet weak var gridView: UICollectionView!
    @IBOutlet weak var yourTurnLabel: UILabel!
    @IBOutlet weak var currentPlayerStack: UIStackView!
    
    let connectionService = ConnectionService.sharedManager
    
    let animationDuration = 0.2
    var game = GameManager.sharedManager
    var yourTurn: Bool? {
        didSet {
            print("DidSet: yourTurn to \(yourTurn)")
            guard let yourTurn = yourTurn else {
                yourTurnLabel.isHidden = true
                return
            }
            yourTurnLabel.isHidden = false
            
            self.yourTurnLabel.text = "\(yourTurn ? "Your":"Their") Turn"
            self.yourTurnLabel.textColor = yourTurn ? ColorScheme.green : ColorScheme.red
            
        }
    }
    var playerX: Bool? {
        
        didSet {
            print("DidSet: playerX to \(playerX)")
            guard let playerX = playerX else {
                currentPlayerStack.isHidden = true
                return
            }
            currentPlayerStack.isHidden = false
            currentPlayerImage.image = playerX ? X : O
            
        }
    }
    
    let X = UIImage(named: "crossred.png")
    let O = UIImage(named: "redcircle.png")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connectionService.gamePlayDelegate = self
        game.initializeGrid()
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
        
        let master = game.master ?? false
        if (!master) { //If you are the slave, notify the master
            connectionService.send(data: "master")
        }
    }
    
    func initialize() {
        game.initializeGame()
        DispatchQueue.main.async {
            self.playerX = self.game.playerX
            self.yourTurn = self.game.yourTurn
            self.gridView.performBatchUpdates({
                self.gridView.reloadSections(IndexSet(integer: 0))
            }, completion: nil)
        }
        
    }
    
    func goToMainScreen() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let connectionVC = storyBoard.instantiateViewController(withIdentifier: "ConnectionView") as! ConnectionViewController
        self.present(connectionVC, animated: true, completion: nil)
    }
    
    //MARK: Collection View Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return game.size * game.size
    }
    
    // Adjust number of rows & columns - by adjusting size of cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let minSpacing = CGFloat(2 * (game.size - 1))
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
            case .notSelected:
                grid.image.isHidden = true
                break
            case .playerX:
                grid.image.isHidden = false
                grid.image.image = UIImage(named: "crossred.png")
                break
            case .playerO:
                grid.image.isHidden = false
                grid.image.image = UIImage(named: "redcircle.png")
                break
        }
        
        //grid.backgroundColor = (index % 2 == 0) ? .green : .blue
        
        return grid
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let yourTurn = yourTurn else {
            print("DeveloperWarning: yourTurn was found to be nil")
            return
        }
        if (yourTurn) {
            didSelectAt(indexPath.item)
        }
    }
    
    func didSelectAt(_ index: Int) {
        guard (game.getStatusAt(index) == .notSelected) else { return }
        
        self.yourTurn = false
        connectionService.send(data: "\(index)")
        
        game.selectedCount += 1
        
        let isX = game.playerX
        game.updateStatusAtIndex(status: (isX ? .playerX : .playerO), index: index)
    
        UIView.animate(withDuration: animationDuration, animations: {
            self.gridView.reloadItems(at: [IndexPath(item: index, section: 0)])
        })
        checkWinCase(index)
    }
    
    func theySelectedAt(_ index: Int) {
        game.selectedCount += 1
        let isX = game.playerX
        game.updateStatusAtIndex(status: isX ? .playerO : .playerX, index: index)
        UIView.animate(withDuration: animationDuration, animations: {
            self.gridView.reloadItems(at: [IndexPath(item: index, section: 0)])
        })
        checkWinCase(index)
    }
    
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
    
    
}

extension GameViewController : GamePlayDelegate {
    func gamePlayReceived(manager: ConnectionService, message: String) {
        print("Game Play Received = \(message)")
        
        if (message == "master") { //Initialize game and set the image
            game.master = true
            game.initializeGame()
            DispatchQueue.main.async {
                self.yourTurn = self.game.yourTurn
                self.playerX = self.game.playerX
            }
        } else if (message == "X" || message == "O") {
            game.playerX = (message == "X")
            game.yourTurn = game.playerX
            DispatchQueue.main.async {
                self.initialize()
            }
        } else {
            guard let index = Int(message) else { return }
            game.yourTurn = true
            DispatchQueue.main.async {
                self.yourTurn = true
                self.theySelectedAt(index)
            }
        }
        
    }
    
    func disconnectReceived(manager: ConnectionService) {
        print("Other device has disconnected. Connections remaining: \(connectionService.session.connectedPeers.count)")
        let alert = UIAlertController(title: "Oops!", message: "Looks like your friend has disconnected. Please try connecting again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ouch :/", style: .default, handler: { action in
            self.goToMainScreen()
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
