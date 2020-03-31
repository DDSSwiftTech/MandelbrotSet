//
//  Mandelbrot.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

extension CGVector {
    static func +(lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
}

class Mandelbrot {
    class func calculate(x: Double, y: Double, i: Int) -> Int {
        var z = CGVector(dx: 0, dy: 0)
        
        for passno in 0..<i {
            z = CGVector(dx: pow(z.dx, 2) - pow(z.dy, 2), dy: 2 * z.dx * z.dy) + CGVector(dx: x, dy: y)
            
            if (pow(z.dx, 2) + pow(z.dy, 2)) >= 4 {
                return passno
            }
        }
        
        return i - 1
    }
}
