//
//  AX25Frame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 5/26/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation


protocol AX25Frame {
    var toCall: CallSignSSID { get }
    var fromCall: CallSignSSID { get }
    var repeaters: Set<CallSignSSID> { get }
    var repeatedBy: Set<CallSignSSID> { get }
    var commandResponse: CommandResponse { get }
    
    // func asBytes()
}

enum Modulo {
    case Eight, OneTwentyEight
}

enum CommandResponse {
    case Command, Response
}

enum Errors: Error {
    case Frame(number: UInt8, outOfBoundsFor: Modulo)
    case Repeaters(repeaters: Set<CallSignSSID>, notSuperSetOf: Set<CallSignSSID>)
    case ParseError(parsing: String)
}


func GetFrame() throws -> AX25Frame {
    return try SFrame(function: .RR, nextReceive: 6, toCall: CallSignSSID(callSign: "K1CHN", ssid: 4)!, fromCall: CallSignSSID(callSign: "KU0L", ssid: 2)!, commandResponse: .Command, pollFinal: true)

}
func ParseFrame(from bytes: Data, withModulo modulo: Modulo) throws -> AX25Frame {
    
    return try SFrame(function: .RR, nextReceive: 6, toCall: CallSignSSID(callSign: "K1CHN", ssid: 4)!, fromCall: CallSignSSID(callSign: "KU0L", ssid: 2)!, commandResponse: .Command, pollFinal: true)
}



func getControlField(from data: Data, with modulo: Modulo) throws -> UInt16 {
    switch modulo {
    case .Eight:
        guard let byte = data.first else {
            throw Errors.ParseError(parsing: "modulo 8 control field")
        }
        return UInt16(byte)
    case .OneTwentyEight:
        guard data.count >= 2 else {
            throw Errors.ParseError(parsing: "modulo 128 control field")
        }
        let controlBytes = data.prefix(2)
        guard controlBytes.count == 2 else {
            throw Errors.ParseError(parsing: "modulo 128 control field")
        }
        print("controlBytes: \(controlBytes)")
        print("startindex: \(controlBytes.startIndex) (controlBytes[controlBytes.startIndex])")
        print("endIndex: \(controlBytes.endIndex) (controlBytes[controlBytes.endIndex])")


        let controlField: UInt16 = UInt16(controlBytes[controlBytes.startIndex]) | (UInt16(controlBytes[controlBytes.startIndex + 1]) << 8)
        return controlField
    }
}


//struct Frame: AX25Frame {
//
//
//    let toCall: CallSignSSID
//    let fromCall: CallSignSSID
//    var repeaters: [CallSignSSID] // all of the repeaters
//    var repeatedBy: [CallSignSSID] // just the ones that have repeated
//
//    let frameType: FrameType
//    // TODO: figure out how to make these required based on frame type. something something polymorphism?
//    var command: Command?
//    var control: Control?
//    let commandFrame: Bool
//    let responseFrame: Bool
//
//    var nextReceive: UInt8?
//    var nextSend: UInt8?
//    let pollFinal: Bool
//
//    // should I symbolize this somehow? and/or validate it? The spec has some specific values,
//    // but does it really matter at this level?
//    var protocolId: UInt8?
//
//    var information: Data?
//
//    init?(_ frameData: Data) {
//        guard frameData.count >= 15 else { // possibly not an ax25 frame? minimum frame size is 15 (without flag fields
//            return nil
//        }
//        var offset = frameData.startIndex
//
//        // callsign fields. 2 or more, depending on number of repeaters the packet has passed through (or is supposed to pass through?)
//        // To, From, Repeaters?...
//        // from the spec:
//        // This address sequence provides the receivers of frames time to check the destination address subfield to see if the frame is addressed to them while the rest of the frame is being received
//        // ... and ...
//        // Evolving consensus opinion is that repeater chaining belongs to a higher protocol layer. Consequently, it is being phased out of Layer 2, although backward compatibility is being maintained with a limit of two repeaters
//        // ...
//        // however, since we can tell when we've reached the end of the list, we'll slurp them all in. We'll worry about the 2 repeater limit when generating frames
//        // and we don't really care about "time" since at this point we've already received the frame ;-)
//
//        var callSignFields: [CallSignField] = []
//        while true {
//            guard offset + 7 < frameData.endIndex else {
//                // we ran out of frame before we finished parsing
//                return nil
//            }
//
//            // TODO: de-static-ify this? or is that fine? Or should CallSignField just take this as an initializer
//            guard let callSignField = CallSignField(frameData[(offset)..<(7+offset)]) else {
//                return nil
//            }
//            callSignFields.append(callSignField)
//            offset += 7
//            // address extension bit is set to 1 on the last callsign field
//            if callSignField.extensionBit {
//                break
//            }
//        }
//
//        let toField = callSignFields[0]
//        let fromField = callSignFields[1]
//
//        switch (toField.sevenBit, fromField.sevenBit) {
//        case (true, false), (false, false):
//            commandFrame = true
//            responseFrame = false
//        case (false, true), (true, true):
//            commandFrame = false
//            responseFrame = true
//        }
//
//        toCall = toField.callSignSSID
//        fromCall = fromField.callSignSSID
//
//        let repeaterFields = Array(callSignFields.suffix(from: 2))
//        repeaters = repeaterFields.map({ $0.callSignSSID })
//        repeatedBy = repeaterFields.filter({ $0.sevenBit }).map({ $0.callSignSSID })
//
//
//        guard offset < frameData.endIndex else {
//            // we ran out of frame before we finished parsing
//            return nil
//        }
//
//        // control field
//        let controlField = frameData[offset] // currently just modulo8. TODO: implement modulo128 support
//
//        if controlField & 0b01 == 0b00 {
//            frameType = .I
//            nextReceive = 0b11100000 & controlField >> 5
//            nextSend =    0b00001110 & controlField >> 1
//        } else if controlField & 0b11 == 0b01 {
//            frameType = .S
//            nextReceive = 0b11100000 & controlField >> 5
//            guard let tryCommand = Command.init(rawValue: (controlField & 0b00001100) >> 2) else {
//                return nil
//            }
//            command = tryCommand
//        } else {
//            frameType = .U
//            guard let tryControl = Control.init(rawValue: (controlField & 0b11101100)) else {
//                return nil
//            }
//            control = tryControl
//        }
//
//        pollFinal = (0b00010000 & controlField >> 4) == 0b00000001
//
//        offset += 1
//
//        switch (frameType, control) {
//        case (.I, _), (.U, .UI?):
//            guard offset < frameData.endIndex else {
//                return nil
//            }
//            protocolId = frameData[offset]
//            information = frameData.suffix(from: offset + 1)
//        case (.U, .XID?):
//            information = frameData.suffix(from: offset)
//            // TODO: further parse this
//        case (.U, .TEST?):
//            information = frameData.suffix(from: offset)
//        case (.U, .FRMR?):
//            information = frameData.suffix(from: offset)
//            guard let information = information else {
//                return nil
//            }
//            guard information.count == 3 else {
//                return nil
//            }
//        default:
//            guard offset == frameData.endIndex else {
//                return nil
//            }
//        }
//    }
//
