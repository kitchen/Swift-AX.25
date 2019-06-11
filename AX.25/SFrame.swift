//
//  SFrame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

enum Command: UInt8 {
    case RR = 0b00
    case RNR = 0b01
    case REJ = 0b10
    case SREJ = 0b11
}

struct SFrame: AX25Frame {
    let toCall: CallSignSSID
    let fromCall: CallSignSSID
    let repeaters: [CallSignSSID]
    let repeatedBy: [CallSignSSID]
    let modulo: Modulo
}
