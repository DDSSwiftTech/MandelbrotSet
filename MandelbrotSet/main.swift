//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa
import CoreGraphics

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
    width: bitmap.cgImage!.height ,
    height: bitmap.cgImage!.height )

let inclusivePixel = [255, 150, 0, 0]

let exclusivePixel = [255, 0, 150, 0]

for x in 0..<Int(rect.width) {
    for y in 0..<Int(rect.height) {
        
        let iterations = Mandelbrot.calculate(x: Double(-2 + CGFloat(x) / rect.height * 4),
                                              y: Double(-2 + CGFloat(y) / rect.height * 4), i: 20)
        
        var pixel = (iterations < 19 ? inclusivePixel : exclusivePixel)
        
        bitmap.setPixel(
            &pixel,
            atX: x ,
            y: y )
    }
}

let displayBounds = CGDisplayBounds(CGMainDisplayID())

let adjustedDisplayBounds = CGRect(x: (displayBounds.width - displayBounds.height) / 2, y: 0, width: displayBounds.width, height: displayBounds.height)

ctx.draw(bitmap.cgImage!, in: adjustedDisplayBounds)

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
                URL(fileURLWithPath: NSHomeDirectory() + "/Desktop/\( Date(timeIntervalSinceNow: TimeInterval(TimeZone.current.secondsFromGMT())) ).jp2",
                    isDirectory: false) as CFURL,
                kUTTypeJPEG2000, 1, nil) {
                
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

