//
//  KeyTracker.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/22/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

func generateKeyTracker() -> CFMachPort {
    
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
    
    return keyDownTracker
}
