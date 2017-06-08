//
//  Julia.swift
//  JuliaSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation
import simd

class Julia {
    class func calculate(x: Double, y: Double, i: Int) -> Int {
        
        var z = vector2(x, y)
        
        for passno in 0..<i {
            
            if (pow(z.x, 2) + pow(z.y, 2)) > 4 {
                return passno
            }
            
            z = vector2(pow(z.x, 2) - pow(z.y, 2), 2 * z.x * z.y) - z
        }
        
        return i - 1
    }
}
