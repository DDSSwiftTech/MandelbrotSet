//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

class MandelbrotDrawClass {
    let maxIterations = 210
    var Ox: Double = -2 {
        willSet {
            print("old Ox: \(Ox)")
        }
        didSet {
            print("new Ox: \(Ox)")
        }
    }
    var Oy: Double = -2 {
        willSet {
            print("old Oy: \(Oy)")
        }
        didSet {
            print("new Oy: \(Oy)")
        }
    }
    var Lx: Double = 4 {
        willSet {
            print("old Lx: \(Lx)")
        }
        didSet {
            print("new Lx: \(Lx)")
        }
    }
    var Ly: Double = 4 {
        willSet {
            print("old Ly: \(Ly)")
        }
        didSet {
            print("new Ly: \(Ly)")
        }
    }
    
    let height = Int(ProcessInfo.processInfo.arguments[1]) ?? 1000
    let width = Int(ProcessInfo.processInfo.arguments[1]) ?? 1000
    let rect: CGRect
    var randomColorList: [Int: NSColor] = [:]
    
    let saveThread = DispatchQueue(label: "savethread")
    let colorAddQueue = DispatchQueue(label: "colorAddQueue")
    
    init() {
        rect = CGRect(
            x: (CGFloat(self.width) - CGFloat(self.height)) / 2,
            y: 0,
            width: CGFloat(self.width),
            height: CGFloat(self.height)
        )
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "draw"), object: nil, queue: nil) { (aNotification) in
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomDec"), object: nil, queue: nil) { (aNotification) in
            
            self.Ox -= self.Lx / 2
            self.Oy -= self.Ly / 2
            
            self.Lx *= 2
            self.Ly *= 2
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomInc"), object: nil, queue: nil) { (aNotification) in
            
            self.Ox += self.Lx / 4
            self.Oy += self.Ly / 4
            
            self.Lx /= 2
            self.Ly /= 2
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecX"), object: nil, queue: nil) { (aNotification) in
            self.Ox -= self.Lx / 4
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncX"), object: nil, queue: nil) { (aNotification) in
            self.Ox += self.Lx / 4
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecY"), object: nil, queue: nil) { (aNotification) in
            self.Oy -= self.Ly / 4
            
            self.draw()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncY"), object: nil, queue: nil) { (aNotification) in
            self.Oy += self.Ly / 4
            
            self.draw()
        }
    }
    
    func draw() {
        
        // iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
        // as well as how many iterations it took to leave the set
        //            for max_iterations in 0..<self.maxIterations {
        
        let piece_axis_max = 100
        let height_piece = Int(self.rect.height) / piece_axis_max
        let width_piece = Int(self.rect.width) / piece_axis_max
        
        for i in 0...maxIterations {
            self.randomColorList[i] = NSColor(
                calibratedRed: CGFloat(arc4random()) / CGFloat(UInt32.max),
                green: CGFloat(arc4random()) / CGFloat(UInt32.max),
                blue: CGFloat(arc4random()) / CGFloat(UInt32.max),
                alpha: CGFloat(arc4random()) / CGFloat(UInt32.max))
        }
        
        DispatchQueue.concurrentPerform(iterations: piece_axis_max) { (piece_x) in
            DispatchQueue.concurrentPerform(iterations: piece_axis_max) { (piece_y) in
                autoreleasepool {
                    let rep = NSBitmapImageRep(
                        bitmapDataPlanes: nil,
                        pixelsWide: width_piece,
                        pixelsHigh: height_piece,
                        bitsPerSample: 8,
                        samplesPerPixel: 4,
                        hasAlpha: true,
                        isPlanar: false,
                        colorSpaceName: NSColorSpaceName.deviceRGB,
                        bytesPerRow: self.width * 4,
                        bitsPerPixel: 32
                    )
                    
                    for x in stride(from: piece_x * width_piece, through: (piece_x + 1) * width_piece, by: 1) {
                        for y in stride(from: piece_y * height_piece, through: (piece_y + 1) * height_piece, by: 1) {
                            let calcX = self.Ox + Double(x) / Double(self.rect.width) * self.Lx
                            let calcY = self.Oy + Double(y) / Double(self.rect.height) * self.Ly
                            
                            let iterations = Mandelbrot.calculate(
                                x: calcX,
                                y: calcY,
                                i: self.maxIterations
                            )
                            
                            rep?.setColor(self.randomColorList[iterations]!, atX: x % width_piece, y: y % height_piece)
                        }
                    }
                    
                    saveThread.async {
                        try! rep!.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "/Users/davidschwartz/MandelbrotPieces/mandelbrot_\(piece_y)_\(piece_x).png"))
                    }
                }
            }
        }
        
        //        colorQueue.async(flags: .barrier) {
        //            self.imageProcessingQueue.async(flags: .barrier) {
        //                exit(0)
        //            }
        //        }
    }
}

let drawObject = MandelbrotDrawClass()

drawObject.draw()
