//
//  StructWrapper.swift
//  MandelbrotSet
//
//  Created by David Schwartz on 6/27/17.
//  Copyright © 2017 DDS Programming. All rights reserved.
//

import Foundation

class StructWrapper<T>: NSObject {
    
    let value: T
    
    init(_ _struct: T) {
        self.value = _struct
    }
}
