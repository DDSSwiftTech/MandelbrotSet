//
//  Mandelbrot.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

struct vector2 {
    
    let x: Double
    let y: Double
    
    init(_ __x: Double, _ __y: Double) {
        x = __x
        y = __y
    }
    
    static func +(lhs: vector2, rhs: vector2) -> vector2 {
        return vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
}

class Mandelbrot {
    class func calculate(x: Double, y: Double, i: Int) -> Int {
        var z = vector2(0, 0)
        
        for passno in 0..<i {
            
            z = vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + vector2(x, y)
            
            if (z.x * z.x + z.y * z.y) >= 4 {
                return passno
            }
        }
        
        return i - 1
    }
}
