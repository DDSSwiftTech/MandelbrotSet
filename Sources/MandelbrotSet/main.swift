//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

class MandelbrotDrawClass {
    
    let maxIterations = 2000
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
    
    let displayBounds = CGDisplayBounds(CGMainDisplayID()) // get the bounds of the main display
    let rect: CGRect
    let ctx: CGContext!
    let drawQueue = DispatchQueue(label: "drawQueue")
    
    var randomColorList: [Int: NSColor] = [:]
    let bitmapModificationQueue = DispatchQueue(label: "bitmapModificationQueue")
    let image: CGImage
    
    let cacheQueue = DispatchQueue(label: "CacheQueue")
    
    var iterationCountCache = Dictionary<hashable_double2, Int>()
    var bitmapCache = Dictionary<hashable_double4, NSBitmapImageRep>()
    let colorQueue = DispatchQueue(label: "colorQueue")
    
    init() {
        
        CGDisplayCapture(CGMainDisplayID())
        
        ctx = CGDisplayGetDrawingContext(CGMainDisplayID())
        
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            FileHandle.standardError.write("Failed to get create image\n".data(using: .utf8)!)
            exit(1)
        }
        
        self.image = image
        
        rect = CGRect(
            x: (image.width - image.height) / 2,
            y: 0,
            width: image.height,
            height: image.height )
        
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
        
        DispatchQueue.global().async {
            
            // adjust the display bounds so that the bitmap is drawn centered
            
            let adjustedDisplayBounds = CGRect(
                x: (self.displayBounds.width - self.displayBounds.height) / 2,
                y: 0,
                width: self.displayBounds.width,
                height: self.displayBounds.height
            )
            
            if let _bitmap = self.bitmapCache[hashable_double4(x: self.Ox, y: self.Oy, z: self.Lx, w: self.Ly)] {
                self.bitmapModificationQueue.sync(flags: .barrier) {
                    
                    // a way of resetting the display each time
                    
                    self.ctx.draw(
                        self.image,
                        in: self.displayBounds)
                    
                    self.ctx.draw(
                        _bitmap.cgImage!,
                        in: adjustedDisplayBounds)
                }
                
            } else {
                
                let bitmap = NSBitmapImageRep(cgImage: self.image)
                
                // iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
                // as well as how many iterations it took to leave the set
                
                DispatchQueue.concurrentPerform(iterations: Int(self.rect.width)) { (x) in
                    DispatchQueue.concurrentPerform(iterations: Int(self.rect.height)) { (y) in
                        // performing each piece of this arithmetic with Double rather than Double or CGFloat yields higher-resolution results
                        
                        let calcX = self.Ox + Double(x) / Double(self.rect.width) * self.Lx
                        let calcY = self.Oy + Double(y) / Double(self.rect.height) * self.Ly
                        
                        let iterations: Int
                        
                        if let countForPixel = self.iterationCountCache[hashable_double2(x: calcX, y: calcY)] {
                            iterations = countForPixel
                        } else {
                            
                            iterations = Mandelbrot.calculate(
                                x: calcX,
                                y: calcY,
                                i: self.maxIterations
                            )
                            
                            self.cacheQueue.async {
                                self.iterationCountCache[hashable_double2(x: calcX, y: calcY)] = iterations
                            }
                        }
                        
                        self.colorQueue.async {
                            if self.randomColorList[iterations] == nil {
                                self.randomColorList[iterations] = NSColor(
                                    calibratedRed: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                    green: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                    blue: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                    alpha: CGFloat(arc4random()) / CGFloat(UInt32.max))
                            }
                            
                            let pixel: NSColor = self.randomColorList[iterations]!
                            
                            self.bitmapModificationQueue.async {
                                bitmap.setColor(
                                    pixel, atX: x, y: y)
                            }
                        }
                    }
                }
                
                self.colorQueue.sync(flags: .barrier, execute: { () in
                    
                    self.bitmapCache[hashable_double4(x: self.Ox, y: self.Oy, z: self.Lx, w: self.Ly)] = bitmap
                    
                    self.bitmapModificationQueue.sync(flags: .barrier) {
                        
                        // a way of resetting the display each time
                        
                        self.ctx.draw(
                            self.image,
                            in: self.displayBounds)
                        
                        self.ctx.draw(
                            bitmap.cgImage!,
                            in: adjustedDisplayBounds)
                    }
                    
                })
            }
        }
    }
}

let drawObject = MandelbrotDrawClass()

NotificationCenter.default.post(name: NSNotification.Name(rawValue: "draw"), object: nil)

RunLoop.main.add(generateKeyTracker(), forMode: .defaultRunLoopMode)

RunLoop.main.run()

