//
//  Double2Ext.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/22/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation
import simd

extension double2: Hashable {
    
    public var hashValue: Int {
        return Int(self.x.bitPattern * self.y.bitPattern)
    }
    
    public static func ==(lhs: double2, rhs: double2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
