//
//  AX25Frame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 5/26/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

public class AX25Frame {
    public enum FrameType {
        case I
        case S
        case U
    }
    
    public enum Command: UInt8 {
        case RR = 0b00
        case RNR = 0b01
        case REJ = 0b10
        case SREJ = 0b11
    }
    
    public enum Control: UInt8 {
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
    
    public enum Modulo {
        case Eight, OneTwentyEight
    }
    
    public let toCall: CallSignSSID
    public let fromCall: CallSignSSID
    public var repeaters: [CallSignSSID] // all of the repeaters
    public var repeatedBy: [CallSignSSID] // just the ones that have repeated
    
    public let frameType: FrameType
    // TODO: figure out how to make these required based on frame type. something something polymorphism?
    public var command: Command?
    public var control: Control?
    public let commandFrame: Bool
    public let responseFrame: Bool
    
    public var nextReceive: UInt8?
    public var nextSend: UInt8?
    public let pollFinal: Bool
    
    // should I symbolize this somehow? and/or validate it? The spec has some specific values,
    // but does it really matter at this level?
    public var protocolId: UInt8?
    
    public var information: Data?
    
    public init?(_ frameData: Data, modulo: Modulo = .Eight) {
        guard frameData.count >= 15 else { // possibly not an ax25 frame? minimum frame size is 15 (without flag fields
            return nil
        }
        var offset = frameData.startIndex

        // callsign fields. 2 or more, depending on number of repeaters the packet has passed through (or is supposed to pass through?)
        // To, From, Repeaters?...
        // from the spec:
        // This address sequence provides the receivers of frames time to check the destination address subfield to see if the frame is addressed to them while the rest of the frame is being received
        // ... and ...
        // Evolving consensus opinion is that repeater chaining belongs to a higher protocol layer. Consequently, it is being phased out of Layer 2, although backward compatibility is being maintained with a limit of two repeaters
        // ...
        // however, since we can tell when we've reached the end of the list, we'll slurp them all in. We'll worry about the 2 repeater limit when generating frames
        // and we don't really care about "time" since at this point we've already received the frame ;-)
        
        var callSignFields: [CallSignField] = []
        while true {
            guard offset + 7 < frameData.endIndex else {
                // we ran out of frame before we finished parsing
                return nil
            }
            
            // TODO: de-static-ify this? or is that fine? Or should CallSignField just take this as an initializer
            guard let callSignField = CallSignField(frameData[(offset)..<(7+offset)]) else {
                return nil
            }
            callSignFields.append(callSignField)
            offset += 7
            // address extension bit is set to 1 on the last callsign field
            if callSignField.extensionBit {
                break
            }
        }
        
        let toField = callSignFields[0]
        let fromField = callSignFields[1]
        
        switch (toField.sevenBit, fromField.sevenBit) {
        case (true, false), (false, false):
            commandFrame = true
            responseFrame = false
        case (false, true), (true, true):
            commandFrame = false
            responseFrame = true
        }

        toCall = toField.callSignSSID
        fromCall = fromField.callSignSSID
        
        let repeaterFields = Array(callSignFields.suffix(from: 2))
        repeaters = repeaterFields.map({ $0.callSignSSID })
        repeatedBy = repeaterFields.filter({ $0.sevenBit }).map({ $0.callSignSSID })
        
        
        
        guard let frameTypeInfo = FrameTypeInfo(fromRaw: frameData.suffix(from: offset), modulo: modulo) else {
            return nil
        }
        
        frameType = frameTypeInfo.frameType
//        switch frameType {
//        case .I:
//            nextSend = frameTypeInfo.nextSend
//            nextReceive = frameTypeInfo.nextReceive
//        case .S:
//            nextReceive =
//        }
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
    }
    
    private struct FrameTypeInfo {
        let frameType: FrameType
        let remainder: Data
        let control: Control?
        let command: Command?
        let nextSend: UInt8?
        let nextReceive: UInt8?
        let pollFinal: Bool
        
        init?(fromRaw frameData: Data, modulo: Modulo = .Eight) {
            guard let controlByte = frameData.first else {
                return nil
            }
            
            // in the nodejs ax25 library: https://github.com/echicken/node-ax25/blob/e2f957c0067d83fda7af826ff7e650187c3eb892/Packet.js#L373
            // it just & with the frametype enum and sees if it's a match. there's probably a way to do that with switch/case, otherwise I can just if elseif elsif
            // then I'm not hardcoding the binary in here, which I think is probably good, leave that in the enum definition
            switch controlByte {
            case let _ where _ & FrameType.U == FrameType.U:
                self.init(SFrame: frameData, modulo: modulo)
            case let _ where _ & FrameType.S == FrameType.S:
                self.init(UFrame: frameData)
            default:
                self.init(IFrame: frameData, modulo: modulo)
            }
        }
        
        private init?(UFrame frameData: Data) {
            frameType = .U
            guard let controlField: UInt8 = frameData.first else {
                // in theory we've already done this, but just gonna guard
                return nil
            }
            pollFinal = (controlField & 0b00010000) == 0b00010000
            // TODO: more parsing here, but we'll just stuff it all into remainder for now
            // even if there's not supposed to be any more data. just TODO for now.
            remainder = frameData.suffix(from: frameData.startIndex + 1)
        }
        
        private init?(IFrame frameData: Data, modulo: Modulo = .Eight) {
            frameType = .I
            switch modulo {
            case .Eight:
                guard let controlField: UInt8 = frameData.first else {
                    // in theory we've already done this, but just gonna guard
                    return nil
                }
                nextReceive = 0b11100000 & controlField >> 5
                nextSend =    0b00001110 & controlField >> 1
                pollFinal = controlField & 0b00010000 == 0b00010000
                remainder = frameData.suffix(from: frameData.startIndex + 1)
            case .OneTwentyEight:
                let controlBytes = frameData.prefix(2)
                guard controlBytes.count == 2 else {
                    return nil
                }
                let controlField: UInt16 = UInt16(controlBytes[controlBytes.startIndex]) & (UInt16(controlBytes[controlBytes.endIndex]) << 8)
                nextReceive = UInt8(truncatingIfNeeded: (controlField & 0b1111111000000000) >> 9)
                nextSend = UInt8(truncatingIfNeeded: (controlField & 0b0000000011111110) >> 1)
                pollFinal = controlField & 0b0000000100000000 == 0b0000000100000000
                remainder = frameData.suffix(from: frameData.startIndex + 2)
            }
            
        }
        
        private init?(SFrame frameData: Data, modulo: Modulo = .Eight) {
            frameType = .S
            switch modulo {
            case .Eight:
                guard let controlField: UInt8 = frameData.first else {
                    // in theory we've already done this, but just gonna guard
                    return nil
                }
                guard frameData.suffix(from: frameData.startIndex + 1).count == 0 else {
                    // there shouldn't be anything else in an S frame, so for now I'm gonna bail out?
                    return nil
                }
                
                frameNumber = (controlField & 0b11100000) >> 5
                control = Control(rawValue: (controlField & 0b1100) >> 2)
                pollFinal = controlField & 0b00010000 == 0b00010000
            case .OneTwentyEight:
                let controlBytes = frameData.prefix(2)
                guard controlBytes.count == 2 else {
                    return nil
                }
                guard frameData.suffix(from: frameData.startIndex + 2).count == 0 else {
                    // there shouldn't be anything else in an S frame, so for now I'm gonna bail out?
                    return nil
                }

                let controlField: UInt16 = UInt16(controlBytes[controlBytes.startIndex]) & (UInt16(controlBytes[controlBytes.endIndex]) << 8)
                frameNumber = UInt8(truncatingIfNeeded: (controlField & 0b1111111000000000) >> 9)
                control = Control(rawValue: UInt8(truncatingIfNeeded: (controlField & 0b1100) >> 2))
                pollFinal = controlField & 0b0000000100000000 == 0b0000000100000000
            }
        }
    }


    private struct CallSignField {
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
}
