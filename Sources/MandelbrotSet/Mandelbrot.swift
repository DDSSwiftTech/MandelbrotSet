//
//  Mandelbrot.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

struct Vector80 {
    let dx: Float80
    let dy: Float80
    
    static func +(lhs: Vector80, rhs: Vector80) -> Vector80 {
        return Vector80(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
}

class Mandelbrot {
    class func calculate(x: Float80, y: Float80, i: Int) -> Int {
        var z = Vector80(dx: 0, dy: 0)
        
        for passno in 0..<i {
            z = Vector80(dx: z.dx * z.dx - z.dy * z.dy, dy: 2 * z.dx * z.dy) + Vector80(dx: x, dy: y)
            
            if (z.dx * z.dx + z.dy * z.dy) >= 4 {
                return passno
            }
        }
        
        return i - 1
    }
}
