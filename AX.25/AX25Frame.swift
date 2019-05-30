//
//  AX25Frame.swift
//  AX.25
//
//  Created by Jeremy Kitchen on 5/26/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import Foundation

// TODO: I think this should be a Struct type. And so should KISS probably. That would probably make things easier.


public class AX25Frame {
    public enum AX25FrameError: Error {
        case parseError
        case parseFrameType
        case parseCommand
        case parseControl
    }
    
    public struct CallSignSSID {
        let CallSign: String
        let SSID: UInt8
        let H: Bool
    }
    
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
    public let repeaters: [CallSignSSID]
    
    public let frameType: FrameType
    // TODO: figure out how to make these required based on frame type. something something polymorphism?
    public var command: Command?
    public var control: Control?
    
    public var nextReceive: UInt8?
    public var nextSend: UInt8?
    public let pollFinal: Bool
    
    // should I symbolize this somehow? and/or validate it? The spec has some specific values,
    // but does it really matter at this level?
    public var protocolId: UInt8?
    
    public var information: Data?
    
    public init(_ frameData: Data) throws {
        guard frameData.count >= 15 else { // possibly not an ax25 frame? minimum frame size is 15 (without flag fields
            throw AX25FrameError.parseError
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
        var callSignFields: [CallSignSSID] = []
        while true {
            guard offset + 7 < frameSize else {
                // we ran out of frame before we finished parsing
                throw AX25FrameError.parseError
            }
            // callsign is the first 6 bytes, left shifted by one bit ("to leave room for the address extension bit") encoded as 7-bit ASCII, only using A-Z 0-9
            let callSignBytes = frameData.subdata(in: ((0+offset)..<(6 + offset)))
            let callSign = String(bytes: callSignBytes.map({ $0 >> 1 }), encoding: String.Encoding.ascii)!.replacingOccurrences(of: " ", with: "")
            
            // the SSID subfield is CRRSSID0
            // C is the "command/response bit" ... or the H bit on repeater fields? Not entirely sure. Section 6.1.2 according to the docs
            // RR are reserved and implementation specific
            // SSID is a UInt4, but swift doesn't have that (natively, there is a pod, I might pull it in, we'll see)
            // address extension bit
            let ssid = (0b00011110 & frameData[6 + offset]) >> 1
            let hBit = (frameData[6+offset] & 0b10000000) == 0b10000000
            
            
            callSignFields.append(CallSignSSID(CallSign: callSign, SSID: ssid, H: hBit))
            offset += 7
            
            // address extension bit is set to 1 on the last callsign field
            if frameData[offset - 1] & 0x01 == 0x01 {
                break
            }
        }
        
        toCall = callSignFields[0]
        fromCall = callSignFields[1]
        repeaters = Array(callSignFields.suffix(from: 2))
        
        guard offset < frameSize else {
            // we ran out of frame before we finished parsing
            throw AX25FrameError.parseError
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
                throw AX25FrameError.parseCommand
            }
            command = tryCommand
        } else {
            frameType = .U
            guard let tryControl = Control.init(rawValue: (controlField & 0b11101100)) else {
                throw AX25FrameError.parseControl
            }
            control = tryControl
        }
        
        pollFinal = (0b00010000 & controlField >> 4) == 0b00000001
        
        offset += 1
        
        // TODO: I, UI, XID, TEST, FRMR frames can all have information fields
        if frameType == .I || (frameType == .U && control == .UI) {
            // slurp up the rest of the frame for I and UI frames
            
            // make sure we at least have one byte left for the protocolId
            guard offset < frameData.count else {
                throw AX25FrameError.parseError
            }
            protocolId = frameData[offset]
            
            // the rest of the frame is payload
            information = frameData.suffix(from: offset + 1)
        } else if frameType == .U && control == .XID {
            information = frameData.suffix(from: offset)
            // TODO: further parse this into XID fields
        } else if frameType == .U && control == .TEST {
            information = frameData.suffix(from: offset)
        } else if frameType == .U && control == .FRMR {
            information = frameData.suffix(from: offset)
            
            // spec says the information field is 3 octets
            if let information = information {
                guard information.count == 3 else {
                    throw AX25FrameError.parseError
                }
            } else {
                // honestly I don't see how this can not be Data
                // .suffix is going to return Data (even if it's just empty) or it's going to explode because index error
                // whatevs
                throw AX25FrameError.parseError
            }
        } else {
            // there shouldn't be anything left
            guard offset == frameData.count else {
                throw AX25FrameError.parseError
            }
        }
    }    
}
