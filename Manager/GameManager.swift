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
    let size = 3 //Hardcoded - TicTacToe is usually 3 x 3?
    var selectedCount = 0
    var playerOne: Bool = true
    
    var grid: [[Grid]] =  []
    
    func initializeGame() {
        selectedCount = 0
        grid = Array(repeating: Array(repeating: Grid(), count: size), count: size)
        
        for i in 0..<size {
            for j in 0..<size {
                grid[i][j] = Grid(.notSelected)
            }
        }
    }
    
    func hasUserWon(_ index: Int) -> winStatus {
        let row = getRowCol(index: index)[0]
        let col = getRowCol(index: index)[1]
        // Have to check if the latest selection satisfies the 3-in-a-row-or-column condition
        
        //Check row:
        if (grid[row][0].status == grid[row][1].status && grid[row][1].status == grid[row][2].status) {
            let status = grid[row][0].status
            if (status != .notSelected) {
                let playerOneHasWon: Bool = (status == .playerOne)
                return (playerOneHasWon == playerOne) ? .won : .lost
            } else {
                return .notYet
            }
        }
        //Check column:
        if (grid[0][col].status == grid[1][col].status && grid[1][col].status == grid[2][col].status) {
            let status = grid[0][col].status
            if (status != .notSelected) {
                let playerOneHasWon: Bool = (status == .playerOne)
                return (playerOneHasWon == playerOne) ? .won : .lost
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
