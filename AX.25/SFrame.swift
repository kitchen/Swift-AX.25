//
//  SFrame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

struct SFrame: AX25Frame {
    enum Function: UInt8 {
        case RR = 0b00
        case RNR = 0b01
        case REJ = 0b10
        case SREJ = 0b11
    }

    let toCall: CallSignSSID
    let fromCall: CallSignSSID
    let repeaters: Set<CallSignSSID>
    let repeatedBy: Set<CallSignSSID>
    let modulo: Modulo
    let commandResponse: CommandResponse
    let nextReceive: UInt8
    let pollFinal: Bool
    let function: Function
    
    init(function: Function, nextReceive: UInt8,
         toCall: CallSignSSID, fromCall: CallSignSSID, commandResponse: CommandResponse, pollFinal: Bool,
         modulo: Modulo = .Eight, repeaters: Set<CallSignSSID> = [], repeatedBy: Set<CallSignSSID> = []) throws {

        guard (modulo == .Eight && nextReceive <= 0b111) || (modulo == .OneTwentyEight && nextReceive <= 0b1111111) else {
            throw Errors.Frame(number: nextReceive, outOfBoundsFor: modulo)
        }
        
        guard repeaters.isSuperset(of: repeatedBy) else {
            throw Errors.Repeaters(repeaters: repeaters, notSuperSetOf: repeatedBy)
        }
        
        self.toCall = toCall
        self.fromCall = fromCall
        self.repeaters = repeaters
        self.repeatedBy = repeatedBy
        self.function = function
        self.nextReceive = nextReceive
        self.modulo = modulo
        self.pollFinal = pollFinal
        self.commandResponse = commandResponse
    }
}
