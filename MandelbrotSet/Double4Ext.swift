//
//  Double4Ext.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/22/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation
import simd

extension double4: Hashable {
    
    public var hashValue: Int {
        return Int(self.x.bitPattern * self.y.bitPattern * self.z.bitPattern * self.w.bitPattern)
    }
    
    public static func ==(lhs: double4, rhs: double4) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
}
