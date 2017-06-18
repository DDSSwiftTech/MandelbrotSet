//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

class MandelbrotDrawClass {
    
    let maxIterations = 750
    
    var zoom: CGFloat = 0
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    let displayBounds = CGDisplayBounds(CGMainDisplayID()) // get the bounds of the main display
    let rect: CGRect
    let ctx: CGContext!
    let drawQueue = DispatchQueue(label: "drawQueue")
    
    var xAdjustedMin: Float80 = -2
    var yAdjustedMin: Float80 = -2
    
    var Lx: Float80 = 4
    var Ly: Float80 = 4
    
    let randomColorList: [[Int]]
    
    let bitmap: NSBitmapImageRep
    
    init() {
        
        var tempColorList: [[Int]] = []
        
        for _ in 0..<maxIterations {
            tempColorList.append([
                Int(arc4random_uniform(256)),
                Int(arc4random_uniform(256)),
                Int(arc4random_uniform(256)),
                255
                ]
            )
        }
        
        randomColorList = tempColorList
        
        CGDisplayCapture(CGMainDisplayID())
        
        ctx = CGDisplayGetDrawingContext(CGMainDisplayID())
        
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            FileHandle.standardError.write("Failed to get create image\n".data(using: .utf8)!)
            exit(1)
        }
        
        bitmap = NSBitmapImageRep(cgImage: image)
        
        rect = CGRect(
            x: (bitmap.cgImage!.width - bitmap.cgImage!.height) / 2,
            y: 0,
            width: bitmap.cgImage!.height,
            height: bitmap.cgImage!.height )
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "draw"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomDec"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                
                self.xAdjustedMin -= self.Lx / 2
                self.yAdjustedMin -= self.Ly / 2
                
                print("new values: xAdjustedMin: \(self.xAdjustedMin), yAdjustedMin: \(self.yAdjustedMin)")
                
                self.Lx *= 2
                self.Ly *= 2
                
                print("new values: Lx: \(self.Lx), Ly: \(self.Ly)")
                
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "zoomInc"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                
                self.xAdjustedMin += self.Lx / 4
                self.yAdjustedMin += self.Ly / 4
                
                print("new values: xAdjustedMin: \(self.xAdjustedMin), yAdjustedMin: \(self.yAdjustedMin)")
                
                self.Lx /= 2
                self.Ly /= 2
                
                print("new values: Lx: \(self.Lx), Ly: \(self.Ly)")
                
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecX"), object: nil, queue: nil) { (aNotification) in
            
            self.drawQueue.async {
                self.xAdjustedMin -= self.Lx / 4
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncX"), object: nil, queue: nil) { (aNotification) in
            
            self.drawQueue.async {
                self.xAdjustedMin += self.Lx / 4
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetDecY"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                self.yAdjustedMin -= self.Ly / 4
                self.draw(bitmap: self.bitmap)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "offsetIncY"), object: nil, queue: nil) { (aNotification) in
            self.drawQueue.async {
                self.yAdjustedMin += self.Ly / 4
                self.draw(bitmap: self.bitmap)
            }
        }
    }
    
    func draw(bitmap: NSBitmapImageRep) {
        
        // iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
        // as well as how many iterations it took to leave the set
        
        for x in 0..<Int(rect.width) {
            for y in 0..<Int(rect.height) {
                
                // performing each piece of this arithmetic with Float80 rather than Double or CGFloat yields higher-resolution results
                
                let iterations = Mandelbrot.calculate(
                    x: xAdjustedMin + Float80(x) / Float80(Double(rect.width)) * Lx,
                    y: yAdjustedMin + Float80(y) / Float80(Double(rect.height)) * Ly,
                    i: self.maxIterations
                )
                
                var pixel = randomColorList[iterations]
                
                bitmap.setPixel(
                    &pixel,
                    atX: x,
                    y: y)
            }
        }
        
        // adjust the display bounds so that the bitmap is drawn centered
        
        let adjustedDisplayBounds = CGRect(x: (displayBounds.width - displayBounds.height) / 2, y: 0, width: displayBounds.width, height: displayBounds.height)
        
        self.ctx!.draw(bitmap.cgImage!, in: adjustedDisplayBounds)
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

