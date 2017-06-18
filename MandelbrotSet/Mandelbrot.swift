//
//  Mandelbrot.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

struct vector2 {
    
    let x: Float80
    let y: Float80
    
    init(_ __x: Float80, _ __y: Float80) {
        x = __x
        y = __y
    }
    
    static func +(lhs: vector2, rhs: vector2) -> vector2 {
        return vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
}

class Mandelbrot {
    class func calculate(x: Float80, y: Float80, i: Int) -> Int {
        var z = vector2(x, y)
        
        for passno in 0..<i {
            
            if (z.x * z.x + z.y * z.y) >= 4 {
                return passno
            }
            
            z = vector2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + vector2(x, y)
        }
        
        return i - 1
    }
}
