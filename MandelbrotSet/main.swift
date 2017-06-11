//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

CGDisplayCapture(CGMainDisplayID())

guard let ctx = CGDisplayGetDrawingContext(CGMainDisplayID()) else {
    FileHandle.standardError.write("Failed to get drawing context\n".data(using: .utf8)!)
    exit(1)
}

guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
    FileHandle.standardError.write("Failed to get create image\n".data(using: .utf8)!)
    exit(1)
}

let bitmap = NSBitmapImageRep(cgImage: image)

var rect = CGRect(
    x: (bitmap.cgImage!.width - bitmap.cgImage!.height) / 2,
    y: 0,
    width: bitmap.cgImage!.height,
    height: bitmap.cgImage!.height )

// iterate through each pixel in the bitmap, and decide if it's inside the Mandelbrot set
// as well as how many iterations it took to leave the set

for x in 0..<Int(rect.width) {
    for y in 0..<Int(rect.height) {
        
        let iterations = Mandelbrot.calculate(x: Double(-2 + CGFloat(x) / rect.width * 4),
                                              y: Double(-2 + CGFloat(y) / rect.height * 4), i: 200)
        
        var pixel = [255, iterations <= 30 ? iterations / 19 * 255 : 0, 0, 0]
        
        bitmap.setPixel(
            &pixel,
            atX: x ,
            y: y )
    }
}

// get the bounds of the main display

let displayBounds = CGDisplayBounds(CGMainDisplayID())

// adjust the display bounds so that the bitmap is drawn centered

let adjustedDisplayBounds = CGRect(x: (displayBounds.width - displayBounds.height) / 2, y: 0, width: displayBounds.width, height: displayBounds.height)

ctx.draw(bitmap.cgImage!, in: adjustedDisplayBounds)

// extra features for saving images, quitting, etc

guard let keyDownTracker = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: { (proxy, type, event, data) -> Unmanaged<CGEvent>? in
        switch event.getIntegerValueField(.keyboardEventKeycode) {
        case 1: // S: Save
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

