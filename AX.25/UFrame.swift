//
//  UFrame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

struct UFrame: AX25Frame {
    enum Modifier: UInt8 {
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
    

    let toCall: CallSignSSID
    let fromCall: CallSignSSID
    let repeaters: Set<CallSignSSID>
    let repeatedBy: Set<CallSignSSID>
    let commandResponse: CommandResponse
    let pollFinal: Bool
    let modifier: Modifier
    let information: Data
    
    
}

