//
//  CallSignSSID.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 5/29/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

let ValidCallSignCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

struct CallSignSSID: Encodable, CustomStringConvertible {
    enum Error: Swift.Error {
        case ssidTooHigh(ssid: UInt8)
        case callSignTooLong(callSign: String)
        case callSignInvalidCharacters(callSign: String)
    }
    
    let callSign: String
    let ssid: UInt8
    var description: String { return "\(callSign)-\(ssid)" }
    
    init(callSign: String, ssid: UInt8) throws {
        self.callSign = callSign.uppercased()
        self.ssid = ssid
        
        guard ssid < 16 else {
            throw Error.ssidTooHigh(ssid: ssid)
        }
        
        guard callSign.count <= 6 else {
            throw Error.callSignTooLong(callSign: callSign)
        }
        
        guard ValidCallSignCharacters.isSuperset(of: CharacterSet(charactersIn: callSign.uppercased())) else {
            throw Error.callSignInvalidCharacters(callSign: callSign)
        }
    }
}

extension CallSignSSID: Decodable {
    // yes, all of this so I can call the validation stuff on init. Weird.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let callSign = try container.decode(String.self, forKey: .callSign)
        let ssid = try container.decode(UInt8.self, forKey: .ssid)
        try self.init(callSign: callSign, ssid: ssid)
    }
}

extension CallSignSSID: Equatable {
    public static func == (lhs: CallSignSSID, rhs: CallSignSSID) -> Bool {
        return lhs.callSign == rhs.callSign && lhs.ssid == rhs.ssid
    }
}
