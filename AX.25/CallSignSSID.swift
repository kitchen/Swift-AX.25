//
//  CallSignSSID.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 5/29/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

public struct CallSignSSID: Equatable {
    let CallSign: String
    let SSID: UInt8 // UInt4 if I end up pulling in that library, perhaps

    public init?(_ bytes: Data) {
        guard bytes.count == 7 else {
            return nil
        }

        let callSignBytes = bytes[bytes.startIndex..<(bytes.endIndex - 1)]
        CallSign = String(bytes: callSignBytes.map({ $0 >> 1 }), encoding: String.Encoding.ascii)!.replacingOccurrences(of: " ", with: "")
        SSID = (0b00011110 & bytes[bytes.endIndex - 1]) >> 1
    }
    
    public init?(callSign CallSign: String, ssid SSID: UInt8) {
        guard SSID <= 15 else {
            return nil
        }
        self.CallSign = CallSign
        self.SSID = SSID
    }
    
    public func field() -> Data {
        var bytes = CallSign.padding(toLength: 6, withPad: " ", startingAt: 0).data(using: .ascii)!.map({ $0 << 1 })
        bytes.append(SSID << 1)
        return Data(bytes)
    }
}
