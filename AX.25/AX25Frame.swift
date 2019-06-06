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
    
    public let toCall: CallSignSSID
    public let fromCall: CallSignSSID
    public var repeaters: [CallSignSSID] // all of the repeaters
    public var repeatedBy: [CallSignSSID] // just the ones that have repeated
    
    public let frameType: FrameType
    // TODO: figure out how to make these required based on frame type. something something polymorphism?
    public var command: Command?
    public var control: Control?
//    public let commandFrame: Bool
//    public let responseFrame: Bool
    
    public var nextReceive: UInt8?
    public var nextSend: UInt8?
    public let pollFinal: Bool
    
    // should I symbolize this somehow? and/or validate it? The spec has some specific values,
    // but does it really matter at this level?
    public var protocolId: UInt8?
    
    public var information: Data?
    
    public init?(_ frameData: Data) {
        guard frameData.count >= 15 else { // possibly not an ax25 frame? minimum frame size is 15 (without flag fields
            return nil
        }
        var offset = 0
        let frameSize = frameData.count
        
        // callsign fields. 2 or more, depending on number of repeaters the packet has passed through
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
            guard offset + 7 < frameSize else {
                // we ran out of frame before we finished parsing
                return nil
            }
            
            // TODO: de-static-ify this? or is that fine? Or should CallSignField just take this as an initializer
            let callSignField = CallSignField(frameData.subdata(in: ((0+offset)..<(7 + offset))))
            callSignFields.append(callSignField)
            offset += 7
            // address extension bit is set to 1 on the last callsign field
            if callSignField.extensionBit {
                break
            }
        }
        
        toCall = callSignFields[0].callSignSSID
        fromCall = callSignFields[1].callSignSSID
        
        let repeaterFields = Array(callSignFields.suffix(from: 2))
        repeaters = repeaterFields.map({ $0.callSignSSID })
        repeatedBy = repeaterFields.filter({ $0.sevenBit }).map({ $0.callSignSSID })
        
        
        guard offset < frameSize else {
            // we ran out of frame before we finished parsing
            return nil
        }
        
        // control field
        let controlField = frameData[offset] // currently just modulo8. TODO: implement modulo128 support
        
        if controlField & 0b01 == 0b00 {
            frameType = .I
            nextReceive = 0b11100000 & controlField >> 5
            nextSend =    0b00001110 & controlField >> 1
        } else if controlField & 0b11 == 0b01 {
            frameType = .S
            nextReceive = 0b11100000 & controlField >> 5
            guard let tryCommand = Command.init(rawValue: (controlField & 0b00001100) >> 2) else {
                return nil
            }
            command = tryCommand
        } else {
            frameType = .U
            guard let tryControl = Control.init(rawValue: (controlField & 0b11101100)) else {
                return nil
            }
            control = tryControl
        }
        
        pollFinal = (0b00010000 & controlField >> 4) == 0b00000001
        
        offset += 1
        
        switch (frameType, control) {
        case (.I, _), (.U, .UI?):
            guard offset < frameData.count else {
                return nil
            }
            protocolId = frameData[offset]
            information = frameData.suffix(from: offset + 1)
        case (.U, .XID?):
            information = frameData.suffix(from: offset)
            // TODO: further parse this
        case (.U, .TEST?):
            information = frameData.suffix(from: offset)
        case (.U, .FRMR?):
            information = frameData.suffix(from: offset)
            guard let information = information else {
                return nil
            }
            guard information.count == 3 else {
                return nil
            }
        default:
            guard offset == frameData.count else {
                return nil
            }
        }

    }

    private struct CallSignField {
        let callSignSSID: CallSignSSID
        let sevenBit: Bool
        let extensionBit: Bool
        
        init(_ bytes: Data) {
            callSignSSID = CallSignSSID(bytes)
            sevenBit = (bytes[6] & 0b10000000 == 0b10000000)
            extensionBit = (bytes[6] & 0b1 == 0b1)
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
