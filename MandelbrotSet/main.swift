//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa
import simd

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
    
    var randomColorList: [Int: [Int]] = [:]
    let bitmapModificationQueue = DispatchQueue(label: "bitmapModificationQueue")
    let image: CGImage
    
    let cacheQueue = DispatchQueue(label: "CacheQueue")
    
    var iterationCountCache = Dictionary<double2, Int>(minimumCapacity: 500000000)
    var bitmapCache = Dictionary<double4, NSBitmapImageRep>(minimumCapacity: 5000)
    
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
            self.drawQueue.async {
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomDec"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                
                self.Ox -= self.Lx / 2
                self.Oy -= self.Ly / 2
                
                self.Lx *= 2
                self.Ly *= 2
                
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomInc"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                
                self.Ox += self.Lx / 4
                self.Oy += self.Ly / 4
                
                self.Lx /= 2
                self.Ly /= 2
                
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecX"), object: nil, queue: nil) { (aNotification) in
            
            self.drawQueue.async {
                self.Ox -= self.Lx / 4
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncX"), object: nil, queue: nil) { (aNotification) in
            
            self.drawQueue.async {
                self.Ox += self.Lx / 4
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecY"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                self.Oy -= self.Ly / 4
                self.draw()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncY"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                self.Oy += self.Ly / 4
                self.draw()
            }
        }
    }
    
    func draw() {
        
        // adjust the display bounds so that the bitmap is drawn centered
        
        let adjustedDisplayBounds = CGRect(x: (displayBounds.width - displayBounds.height) / 2, y: 0, width: displayBounds.width, height: displayBounds.height)
        
        if let _bitmap = self.bitmapCache[double4(Ox, Oy, Lx, Ly)] {
            bitmapModificationQueue.sync(flags: .barrier) {
                
                // a way of resetting the display each time
                
                ctx.draw(
                    image,
                    in: displayBounds)
                
                ctx!.draw(
                    _bitmap.cgImage!,
                    in: adjustedDisplayBounds)
            }
            
        } else {
            
            let bitmap = NSBitmapImageRep(cgImage: image)
            
            // iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
            // as well as how many iterations it took to leave the set
            
            DispatchQueue.concurrentPerform(iterations: Int(rect.width)) { (x) in
                DispatchQueue.concurrentPerform(iterations: Int(rect.height)) { (y) in
                    // performing each piece of this arithmetic with Double rather than Double or CGFloat yields higher-resolution results
                    
                    
                    let calcX = Ox + Double(x) / Double(rect.width) * Lx
                    let calcY = Oy + Double(y) / Double(rect.height) * Ly
                    
                    let iterations: Int
                    
                    if let countForPixel = iterationCountCache[double2(calcX, calcY)] {
                        iterations = countForPixel
                    } else {
                        
                        iterations = Mandelbrot.calculate(
                            x: calcX,
                            y: calcY,
                            i: self.maxIterations
                        )
                        
                        cacheQueue.async {
                            self.iterationCountCache[double2(calcX, calcY)] = iterations
                        }
                    }
                    
                    var pixel: [Int]
                    
                    if randomColorList[iterations] == nil {
                        randomColorList[iterations] = [
                            Int(arc4random_uniform(256)),
                            Int(arc4random_uniform(256)),
                            Int(arc4random_uniform(256)),
                            Int(arc4random_uniform(256))
                        ]
                    }
                    
                    pixel = randomColorList[iterations]!
                    
                    bitmapModificationQueue.async {
                        bitmap.setPixel(
                            &pixel,
                            atX: x,
                            y: y)
                    }
                }
            }
            
            self.bitmapCache[double4(Ox, Oy, Lx, Ly)] = bitmap
            
            bitmapModificationQueue.sync(flags: .barrier) {
                
                // a way of resetting the display each time
                
                ctx.draw(
                    image,
                    in: displayBounds)
                
                ctx!.draw(
                    bitmap.cgImage!,
                    in: adjustedDisplayBounds)
            }
        }
    }
}

let drawObject = MandelbrotDrawClass()

NotificationCenter.default.post(name: NSNotification.Name(rawValue: "draw"), object: nil)

RunLoop.main.add(generateKeyTracker(), forMode: .defaultRunLoopMode)

RunLoop.main.run()

