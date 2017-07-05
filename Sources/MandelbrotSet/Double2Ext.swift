//
//  Double2Ext.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/22/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

struct hashable_double2: Hashable {
    
    let x: Double
    let y: Double
    
    public let hashValue: Int
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
        self.hashValue = x.hashValue ^ y.hashValue
    }
    
    public static func ==(lhs: hashable_double2, rhs: hashable_double2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

