//
//  Grid.swift
//  TicTac2
//
//  Created by Rushil Nagarsheth on 01/06/19.
//  Copyright © 2019 Rushil Nagarsheth. All rights reserved.
//

import UIKit

enum gridStatus{
    case notSelected
    case playerOne
    case playerTwo
}

class Grid: NSObject {
    var status: gridStatus
    
    override init() {
        status = .notSelected
    }
    
    init(_ status: gridStatus) {
        self.status = status
    }
}
