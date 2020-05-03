//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

class MandelbrotDrawClass {
    let maxIterations = 20000
    var Ox: Float80 = -2 {
        willSet {
            print("old Ox: \(Ox)")
        }
        didSet {
            print("new Ox: \(Ox)")
        }
    }
    var Oy: Float80 = -2 {
        willSet {
            print("old Oy: \(Oy)")
        }
        didSet {
            print("new Oy: \(Oy)")
        }
    }
    var Lx: Float80 = 4 {
        willSet {
            print("old Lx: \(Lx)")
        }
        didSet {
            print("new Lx: \(Lx)")
        }
    }
    var Ly: Float80 = 4 {
        willSet {
            print("old Ly: \(Ly)")
        }
        didSet {
            print("new Ly: \(Ly)")
        }
    }
    
//    let height = Int(ProcessInfo.processInfo.arguments[1]) ?? 1000
//    let width = Int(ProcessInfo.processInfo.arguments[1]) ?? 1000
    let rect: CGRect
    var randomColorList: [Int: NSColor] = [:]
    
    let saveThread = DispatchQueue(label: "savethread")
    let colorAddQueue = DispatchQueue(label: "colorAddQueue")
    let cgContext = CGDisplayGetDrawingContext(CGMainDisplayID())!
    let newContext: NSGraphicsContext
    
    init() {
        for i in 0...maxIterations {
            self.randomColorList[i] = NSColor(
                calibratedRed: CGFloat(arc4random()) / CGFloat(UInt32.max),
                green: CGFloat(arc4random()) / CGFloat(UInt32.max),
                blue: CGFloat(arc4random()) / CGFloat(UInt32.max),
                alpha: CGFloat(arc4random()) / CGFloat(UInt32.max))
        }
        
        newContext = NSGraphicsContext(cgContext: cgContext, flipped: false)
        let tempRect = CGDisplayBounds(CGMainDisplayID())
        rect = CGRect(x: 0, y: 0, width: tempRect.height, height: tempRect.height)
        NSGraphicsContext.current = newContext
        
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
        autoreleasepool {
            let offscreenRep = NSBitmapImageRep(
                bitmapDataPlanes:nil,
                pixelsWide:Int(self.rect.width),
                pixelsHigh:Int(self.rect.height),
                bitsPerSample:8,
                samplesPerPixel:4,
                hasAlpha:true,
                isPlanar:false,
                colorSpaceName:NSColorSpaceName.deviceRGB,
                bitmapFormat:NSBitmapImageRep.Format.alphaFirst,
                bytesPerRow:0,
                bitsPerPixel:0
            )!

            let context = NSGraphicsContext(bitmapImageRep: offscreenRep)!
//            NSGraphicsContext.current = context
            let image = context.cgContext.makeImage()!
            let nsImage = NSImage(cgImage: image, size: self.rect.size)
            var rawTiff = nsImage.tiffRepresentation!
            let bytes = rawTiff.withUnsafeMutableBytes { $0 }
            
            DispatchQueue.concurrentPerform(iterations: Int(self.rect.width)) { (x) in
                for y in 0..<Int(self.rect.height) {
                    let calcX = self.Ox + Float80(x) / Float80(self.rect.width) * self.Lx
                    let calcY = self.Oy + Float80(y) / Float80(self.rect.height) * self.Ly
                    
                    let iterations = Mandelbrot.calculate(
                        x: calcX,
                        y: calcY,
                        i: self.maxIterations
                    )
                        
                    let color = self.randomColorList[iterations]!
                    
                    bytes[8 + 4 * (y * Int(self.rect.height) + x)] = UInt8(color.redComponent * CGFloat(UInt8.max))
                    bytes[9 + 4 * (y * Int(self.rect.height) + x)] = UInt8(color.greenComponent * CGFloat(UInt8.max))
                    bytes[10 + 4 * (y * Int(self.rect.height) + x)] = UInt8(color.blueComponent * CGFloat(UInt8.max))
                    bytes[11 + 4 * (y * Int(self.rect.height) + x)] = 0xff
                }
            }
            
            let resultImage = NSImage(data: rawTiff)
            resultImage?.draw(in: self.rect)
        }
    }
}

CGDisplayCapture(CGMainDisplayID())

let drawObject = MandelbrotDrawClass()

drawObject.draw()

RunLoop.current.add(generateKeyTracker(), forMode: .default)

RunLoop.current.run()
