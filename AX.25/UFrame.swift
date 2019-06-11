//
//  UFrame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

enum Control: UInt8 {
    case SABME = 0b01101100
    case SABM  = 0b00101100
    case DISC  = 0b01000000
    case DM    = 0b00001100
    case UA    = 0b01100000
    case FRMR  = 0b10000100
    case UI    = 0b00000000
    case XID   = 0b10101100
    case TEST  = 0b11100000
}

struct UFrame: AX25Frame {
    let toCall: CallSignSSID
    let fromCall: CallSignSSID
    let repeaters: [CallSignSSID]
    let repeatedBy: [CallSignSSID]
}

