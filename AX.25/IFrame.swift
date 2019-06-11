//
//  IFrame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

struct IFrame: AX25Frame {
    let toCall: CallSignSSID
    let fromCall: CallSignSSID
    let repeaters: [CallSignSSID]
    let repeatedBy: [CallSignSSID]
    let modulo: Modulo
}
