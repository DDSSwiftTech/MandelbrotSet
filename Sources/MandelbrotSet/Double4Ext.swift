//
//  Double4Ext.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/22/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

struct hashable_double4: Hashable {
    
    let x: Double
    let y: Double
    let z: Double
    let w: Double
    
    public let hashValue: Int
    
    init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self.hashValue = x.hashValue ^ y.hashValue ^ z.hashValue ^ w.hashValue
    }
    
    public static func ==(lhs: hashable_double4, rhs: hashable_double4) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
}
