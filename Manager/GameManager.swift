//
//  GameManager.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import Foundation

enum winStatus {
    case won
    case lost
    case notYet
}

class GameManager {
    
    //Singleton Declaration
    static let sharedManager = GameManager()
    
    let connectionService = ConnectionService.sharedManager
    
    let size = 3 //Hardcoded - TicTacToe is usually 3 x 3?
    var selectedCount = 0
    var master: Bool? = nil
    var playerX: Bool = false
    var yourTurn: Bool = false
    
    var grid: [[Grid]] =  []
    
    func initializeGame() {
        print("GAME INTITIALIZED!")
        initializeGrid()
        //Master decides who becomes X and who becomes O
        if (master ?? false) { // Initialize game parameters
            print("You are the master.")
            playerX = Bool.random()
            yourTurn = playerX
            let message = playerX ? "O" : "X"
            connectionService.send(data: message)
        } else { //Slaves dont do anything here
            print("You are the slave")
        }
    }
    
    func initializeGrid() {
        selectedCount = 0
        grid = Array(repeating: Array(repeating: Grid(), count: size), count: size)
        for i in 0..<size {
            for j in 0..<size {
                grid[i][j] = Grid(.notSelected)
            }
        }
    }
    
    func checkWinStatus(_ status: gridStatus) -> winStatus {
        let hasXWon: Bool = (status == .playerX)
        return (hasXWon == playerX) ? .won : .lost
    }
    
    func hasUserWon(_ index: Int) -> winStatus {
        let row = getRowCol(index: index)[0]
        let col = getRowCol(index: index)[1]
        let status = grid[row][col].status
        guard status != .notSelected else { return .notYet }
        // Have to check if the latest selection satisfies the 3-in-a-row-or-column condition
        
        //Check row:
        if (grid[row][0].status == grid[row][1].status && grid[row][1].status == grid[row][2].status) {
            return checkWinStatus(status)
        }
        //Check column:
        if (grid[0][col].status == grid[1][col].status && grid[1][col].status == grid[2][col].status) {
            return checkWinStatus(status)
        }
        var mismatch = false
        //Check Main Diagonal:
        if (row == col) {
            for i in 0..<(size-1){
                if (grid[i][i].status != grid[i+1][i+1].status) {
                    mismatch = true
                    break
                }
            }
            if (!mismatch) {
                return checkWinStatus(status)
            }
        }
        //Check Off Diagonal:
        if ((row+col) == (size-1)) {
            mismatch = false
            for i in 0..<(size-1){
                if (grid[i][size-i-1].status != grid[i+1][size-i-2].status) {
                    mismatch = true
                    break
                }
            }
            if (!mismatch) {
                return checkWinStatus(status)
            }
        }
        return .notYet
    }
    
    func updateStatusAtIndex(status: gridStatus, index: Int) {
        let row = getRowCol(index: index)[0]
        let col = getRowCol(index: index)[1]
        grid[row][col].status = status
    }
    
    func getStatusAt(_ index: Int) -> gridStatus{
        let row = getRowCol(index: index)[0]
        let col = getRowCol(index: index)[1]
        return grid[row][col].status
    }
    
    func getRowCol(index: Int)->[Int] {
        let row: Int = (index/size)
        let col: Int = index % size
        return [row,col]
    }
    
    func getIndex(row: Int, col: Int) -> Int {
        return row*size+col
    }
}
