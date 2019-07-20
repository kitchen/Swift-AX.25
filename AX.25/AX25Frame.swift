////
////  AX25Frame.swift
////  AX.25
////
////  Created by Jeremy Kitchen on 5/26/19.
////  Copyright © 2019 Jeremy Kitchen. All rights reserved.
////

import Foundation

// I'm guessing this will turn into a protocol at some point
struct AX25Frame {
    enum CommandResponse {
        case command, response
    }

    enum CodingKeys: CodingKey {
        case toField, fromField, repeaterFields, payload
    }

    let to: CallSignSSID
    let from: CallSignSSID
    let commandResponse: CommandResponse
    let repeaters: Set<CallSignSSID>
    let repeatedBy: Set<CallSignSSID>
    let payload: Data
}

extension AX25Frame: Encodable {
    private struct CallSignSSIDField: Codable {
        let callSignSSID: CallSignSSID
        let sevenBit: Bool
        let continuationBit: Bool
    }

    private var toField: CallSignSSIDField {
        return CallSignSSIDField(callSignSSID: to, sevenBit: commandResponse == .command, continuationBit: false)
    }

    private var fromField: CallSignSSIDField {
        return CallSignSSIDField(callSignSSID: from, sevenBit: commandResponse == .response, continuationBit: repeaters.isEmpty)
    }

    private var repeaterFields: [CallSignSSIDField] {
        var fields: [CallSignSSIDField] = []
        for (idx, repeater) in repeaters.enumerated() {
            let continuationBit = (idx == repeaters.count - 1)
            let sevenBit = repeatedBy.contains(repeater)
            fields.append(CallSignSSIDField(callSignSSID: repeater, sevenBit: sevenBit, continuationBit: continuationBit))
        }
        return fields
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toField, forKey: .toField)
        try container.encode(fromField, forKey: .fromField)
        try container.encode(repeaterFields, forKey: .repeaterFields)
        try container.encode(payload, forKey: .payload)
    }
}

extension AX25Frame: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fromField = try container.decode(CallSignSSIDField.self, forKey: .fromField)
        from = fromField.callSignSSID

        let toField = try container.decode(CallSignSSIDField.self, forKey: .toField)
        to = toField.callSignSSID

        switch (toField.sevenBit, fromField.sevenBit) {
        case (true, true), (true, false):
            // true, true is the old method, true on just the to is the new method
            commandResponse = .command
        case (false, false), (false, true):
            // false, false is the old method, true on just the from is the new method
            commandResponse = .response
        }

        let repeaterFields = try container.decode([CallSignSSIDField].self, forKey: .repeaterFields)
        var repeaters = Set<CallSignSSID>()
        var repeatedBy = Set<CallSignSSID>()
        for repeaterField in repeaterFields {
            repeaters.insert(repeaterField.callSignSSID)
            if repeaterField.sevenBit {
                repeatedBy.insert(repeaterField.callSignSSID)
            }
        }
        self.repeaters = repeaters
        self.repeatedBy = repeatedBy

        payload = try container.decode(Data.self, forKey: .payload)
    }
}

//
// public struct AX25Frame {
//    public enum FrameType {
//        case I
//        case S
//        case U
//    }
//
//    public enum Command: UInt8 {
//        case RR = 0b00
//        case RNR = 0b01
//        case REJ = 0b10
//        case SREJ = 0b11
//    }
//
//    public enum Control: UInt8 {
//        case SABME = 0b01101100
//        case SABM  = 0b00101100
//        case DISC  = 0b01000000
//        case DM    = 0b00001100
//        case UA    = 0b01100000
//        case FRMR  = 0b10000100
//        case UI    = 0b00000000
//        case XID   = 0b10101100
//        case TEST  = 0b11100000
//    }
//
//    public let toCall: CallSignSSID
//    public let fromCall: CallSignSSID
//    public var repeaters: [CallSignSSID] // all of the repeaters
//    public var repeatedBy: [CallSignSSID] // just the ones that have repeated
//
//    public let frameType: FrameType
//    // TODO: figure out how to make these required based on frame type. something something polymorphism?
//    public var command: Command?
//    public var control: Control?
//    public let commandFrame: Bool
//    public let responseFrame: Bool
//
//    public var nextReceive: UInt8?
//    public var nextSend: UInt8?
//    public let pollFinal: Bool
//
//    // should I symbolize this somehow? and/or validate it? The spec has some specific values,
//    // but does it really matter at this level?
//    public var protocolId: UInt8?
//
//    public var information: Data?
//
//    public init?(_ frameData: Data) {
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
//    private struct CallSignField {
//        let callSignSSID: CallSignSSID
//        let sevenBit: Bool
//        let extensionBit: Bool
//
//        init?(_ bytes: Data) {
//            guard let callSignSSID = CallSignSSID(bytes) else {
//                return nil
//            }
//            self.callSignSSID = callSignSSID
//
//            guard let last = bytes.last else {
//                return nil
//            }
//
//            sevenBit = (last & 0b10000000 == 0b10000000)
//            extensionBit = (last & 0b1 == 0b1)
//        }
//
//        func field() -> Data {
//            var bytes = callSignSSID.field()
//            if sevenBit {
//                bytes[6] |= 0b10000000
//            }
//            if extensionBit {
//                bytes[6] |= 0b1
//            }
//            return bytes
//        }
//    }
// }
