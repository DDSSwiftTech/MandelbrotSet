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
    
    let displayBounds = CGDisplayBounds(CGMainDisplayID()) // get the bounds of the main display
    let rect: CGRect
    let ctx: CGContext!
    let drawQueue = DispatchQueue(label: "drawQueue")
    
    var randomColorList: [Int: [Int]] = [:]
    let bitmapModificationQueue = DispatchQueue(label: "bitmapModificationQueue")
    let image: CGImage
    
    let bitmapCache = NSCache<NSString, NSBitmapImageRep>()
    
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
        
        if let bitmap = bitmapCache.object(forKey: "\(Lx)-\(Ly)-\(Ox)-\(Oy)" as NSString) {
            bitmapModificationQueue.sync(flags: .barrier) {
                
                // a way of resetting the display each time
                
                ctx.draw(
                    image,
                    in: displayBounds)
                
                ctx!.draw(
                    bitmap.cgImage!,
                    in: adjustedDisplayBounds)
            }
        } else {
            
            let bitmap = NSBitmapImageRep(cgImage: image)
            
            // iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
            // as well as how many iterations it took to leave the set
            
            DispatchQueue.concurrentPerform(iterations: Int(rect.width)) { (x) in
                DispatchQueue.concurrentPerform(iterations: Int(rect.height)) { (y) in
                    
                    // performing each piece of this arithmetic with Float80 rather than Double or CGFloat yields higher-resolution results
                    
                    let iterations = Mandelbrot.calculate(
                        x: Ox + Float80(x) / Float80(Double(rect.width)) * Lx,
                        y: Oy + Float80(y) / Float80(Double(rect.height)) * Ly,
                        i: self.maxIterations
                    )
                    
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
            
            bitmapCache.setObject(bitmap, forKey: "\(Lx)-\(Ly)-\(Ox)-\(Oy)" as NSString)
            
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

// extra features for saving images, quitting, etc

guard let keyDownTracker = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: { (proxy, type, event, zoom) -> Unmanaged<CGEvent>? in
        switch event.getIntegerValueField(.keyboardEventKeycode) {
        case 1: // S: Save
            
            let displayBounds = CGDisplayBounds(CGMainDisplayID())
            
            guard (try? FileManager.default.createDirectory(
                atPath: NSHomeDirectory() + "/Desktop/2DShapesCGPictures",
                withIntermediateDirectories: true,
                attributes: nil)) != nil else {
                    break
            }
            
            guard let cgImage = CGDisplayCreateImage(
                CGMainDisplayID(),
                rect:CGRect(
                    x: displayBounds.midX > displayBounds.midY ? displayBounds.midX - displayBounds.midY : displayBounds.midY - displayBounds.midX,
                    y: 0,
                    width: displayBounds.midX > displayBounds.midY ? displayBounds.height : displayBounds.width,
                    height: displayBounds.midX > displayBounds.midY ? displayBounds.height : displayBounds.width
            )) else {
                break
            }
            
            if let destination = CGImageDestinationCreateWithURL(
                URL(fileURLWithPath: NSHomeDirectory() + "/Desktop/\( Date(timeIntervalSinceNow: TimeInterval(TimeZone.current.secondsFromGMT())) ).png",
                    isDirectory: false) as CFURL,
                kUTTypePNG, 1, nil) {
                
                CGImageDestinationAddImage(destination, cgImage, nil)
                CGImageDestinationFinalize(destination)
            }
            
        case 12: // Q: Quit
            exit(0)
            
        case 24: // +: Zoom In
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "zoomInc"), object: nil)
            }
            
        case 27: // -: Zoom Out
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "zoomDec"), object: nil)
            }
            
        case 124:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "offsetIncX"), object: nil)
            }
            
        case 123:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "offsetDecX"), object: nil)
            }
            
        case 126:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "offsetDecY"), object: nil)
            }
            
        case 125:
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "offsetIncY"), object: nil)
            }
            
        default:
            break
        }
        
        return nil
},
    userInfo: nil) else {
        FileHandle.standardError.write("Could not create keyboard tap".data(using: .utf8)!)
        exit(1)
}

RunLoop.main.add(keyDownTracker, forMode: .defaultRunLoopMode)

RunLoop.main.run()

