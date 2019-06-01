//
//  GameViewController.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var gridView: UICollectionView!
    
    var game = GameManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        game.initializeGame()
        
        //Setup Colors
        self.view.backgroundColor = ColorScheme.yellow
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
            case .playerOne:
                grid.image.isHidden = false
                grid.image.image = UIImage(named: "crossred.png")
                break
            case .playerTwo:
                grid.image.isHidden = false
                grid.image.image = UIImage(named: "redcircle.png")
                break
        }
        
        //grid.backgroundColor = (index % 2 == 0) ? .green : .blue
        
        return grid
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard (game.getStatusAt(indexPath.item) == .notSelected) else { return }
        
        game.selectedCount += 1
        
        if (game.selectedCount % 2 == 0) { //Player One
            print("Player 1 selected \(indexPath.item)")
            game.updateStatusAtIndex(status: .playerOne, index: indexPath.item)
        } else { // Player Two
            print("Player 2 selected \(indexPath.item)")
            game.updateStatusAtIndex(status: .playerTwo, index: indexPath.item)
        }
        
        gridView.reloadData()
        checkWinCase(indexPath.item)
        
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
        game.initializeGame()
        gridView.reloadData()
    }
    
}
