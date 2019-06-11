//
//  CallSignField.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

struct CallSignField {
    let callSignSSID: CallSignSSID
    let sevenBit: Bool
    let extensionBit: Bool
    
    init?(_ bytes: Data) {
        guard let callSignSSID = CallSignSSID(bytes) else {
            return nil
        }
        self.callSignSSID = callSignSSID
        
        guard let last = bytes.last else {
            return nil
        }
        
        sevenBit = (last & 0b10000000 == 0b10000000)
        extensionBit = (last & 0b1 == 0b1)
    }
    
    func field() -> Data {
        var bytes = callSignSSID.field()
        if sevenBit {
            bytes[6] |= 0b10000000
        }
        if extensionBit {
            bytes[6] |= 0b1
        }
        return bytes
    }
}

