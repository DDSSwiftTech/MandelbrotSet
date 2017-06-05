//
//  main.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/4/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Cocoa

let maxIter = 20

let displaySize = CGDisplayBounds(CGMainDisplayID())

func colorForColorIDX(_ idx: Int) -> CGColor {
    return NSColor(
        calibratedRed: CGFloat(idx)/(CGFloat(maxIter) - 1),
        green: 1 - CGFloat(idx)/(CGFloat(maxIter) - 1),
        blue: 0,
        alpha: 1).cgColor
}

CGDisplayCapture(CGMainDisplayID())

if let context = CGDisplayGetDrawingContext(CGMainDisplayID()) {
    
    let calcQueue = DispatchQueue(label: "calcQueue",
                                  qos: .userInteractive,
                                  attributes: .concurrent)
    
    let arrayQueue = DispatchQueue(label: "arrayQueue",
                                   qos: .userInteractive)
    
    context.setFillColor(colorForColorIDX(1))
    
    var colorArray: [Int: [CGRect]] = [:]
    
    for i in 0..<maxIter {
        colorArray[i] = []
    }
    
    for x in stride(from: -2, through: 2, by: 0.001) {
        for y in stride(from: -2, through: 2, by: 0.001) {
            
            calcQueue.async {
                
                let selectedColor = Mandelbrot.calculate(
                    x: Double(x),
                    y: Double(y),
                    i: maxIter)
                
                let rect = CGRect(
                    x: Double(displaySize.midX) + Double(displaySize.midY) / 2 * x,
                    y: Double(displaySize.midY) + Double(displaySize.midY) / 2 * y, width: 0.1, height: 0.1)
                
                arrayQueue.async {
                    colorArray[selectedColor]!.append(rect)
                    
                    if colorArray[selectedColor]!.count >= 10000 {
                        context.setFillColor(colorForColorIDX(selectedColor))
                        context.addRects(colorArray[selectedColor]!)
                        context.fillPath()
                        
                        colorArray[selectedColor]!.removeAll(keepingCapacity: true)
                    }
                }
            }
        }
    }
    
    calcQueue.async(flags: .barrier) {
        arrayQueue.async(flags: .barrier) {
            for i in 0..<maxIter {
                context.setFillColor(colorForColorIDX(i))
                context.addRects(colorArray[i]!)
                context.fillPath()
            }
        }
    }
}

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
                    x: displaySize.midX > displaySize.midY ? displaySize.midX - displaySize.midY : displaySize.midY - displaySize.midX,
                    y: 0,
                    width: displaySize.midX > displaySize.midY ? displaySize.height : displaySize.width,
                    height: displaySize.midX > displaySize.midY ? displaySize.height : displaySize.width
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

