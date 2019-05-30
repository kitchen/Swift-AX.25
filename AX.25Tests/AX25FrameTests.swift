//
//  AX25FrameTests.swift
//  AX.25Tests
//
//  Created by Jeremy Kitchen on 5/26/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import XCTest
@testable import AX_25

class AX25FrameTests: XCTestCase {
    func testParseSABMFrame() throws {
        let frameData = Data([0xae, 0x6e, 0x98, 0xa8, 0x40, 0x40, 0xf4, 0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x61, 0x3f])
        let frame = try AX25Frame(frameData)
        XCTAssertEqual(.U, frame.frameType)
        XCTAssertEqual(.SABM, frame.control)
    }
    
    func testParseFrameWith2frameType() throws {
        // initially I was grabbing the last 2 bits of the byte and looking up a static map of frame types based on that
        // Something like: enum FrameType { case I = 0b00, S = 0b01, U = 0b11 }
        // however, with I frames, that second bit there is actually used for other things, so it can sometimes be 1, meaning
        // the "frame type" bits would be 0b10 and therefore fail the lookup. The example here is one such frame.
        // The test is called "2 frame type" because the frame type was being looked up as 0b10, or decimal 2, and failing :)
        let frameData = Data([
            0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0xe0, // to callsign
            0xae, 0x6e, 0x98, 0xa8, 0x40, 0x40, 0x75, // from callsign
            0x06, // control field
            0xf0, 0x43, 0x4d, 0x53, 0x20, 0x76, 0x69, 0x61, 0x20, 0x57, 0x37, 0x4c, 0x54, 0x20, 0x3e, 0x0d
        ])
        
        XCTAssertNoThrow(try AX25Frame(frameData))
        let frame = try AX25Frame(frameData)
        XCTAssertEqual(AX25Frame.FrameType.I, frame.frameType)
    }
    
    func testParseBeaconFrame() throws {
        // this tests 2 bugs I had:
        // 1. BEACON was being parsed as BEACO. Off by one errors are hard mmkay.
        // 2. I had a UI control type, but it was the wrong value. And I was missing the XID control type (its value was assigned to UI)
        let frameData = Data([
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // to callsign: BEACO-0 ... wait why isn't it parsing as BEACON? .. maybe that's a clue ;-)
            0xae, 0x6e, 0x98, 0xa8, 0x40, 0x40, 0x75, //
            0x03, // should be UI
            0xf0, 0x50, 0x41, 0x52, 0x43, 0x20, 0x57, 0x49, 0x4e, 0x4c, 0x49, 0x4e, 0x4b, 0x20, 0x47, 0x41, 0x54, 0x45, 0x57, 0x41, 0x59, 0x20, 0x4f, 0x4e, 0x20, 0x4d, 0x54, 0x20, 0x53, 0x43, 0x4f, 0x54, 0x54, 0x2c, 0x20, 0x43, 0x4e, 0x38, 0x35, 0x52, 0x4b, 0x2c, 0x20, 0x52, 0x45, 0x50, 0x45, 0x41, 0x54, 0x45, 0x52, 0x20, 0x4f, 0x4e, 0x20, 0x31, 0x34, 0x36, 0x2e, 0x38, 0x34, 0x20, 0x2d, 0x36, 0x30, 0x30, 0x2c, 0x20, 0x49, 0x4e, 0x46, 0x4f, 0x40, 0x57, 0x37, 0x4c, 0x54, 0x2e, 0x4f, 0x52, 0x47, 0x0d
        ])
        
        XCTAssertNoThrow(try AX25Frame(frameData))
        let frame = try AX25Frame(frameData)
        XCTAssertEqual(AX25Frame.Control.UI, frame.control)
        XCTAssertEqual("BEACON", frame.toCall.CallSign)
        XCTAssertEqual(0, frame.toCall.SSID)
    }
    
    func testRunOutOfFrame() throws {
        let frameTooShortData = Data([0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, 0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60]) // there's no control field
        XCTAssertThrowsError(try AX25Frame(frameTooShortData))

        // ends before finishing a callsign field
        let runsOutWhileParsingCallsignsData = Data([
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // BEACON-0, extension bit 0
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // BEACON-0, extension bit 0
            0x84, 0x8a, 0x82, 0x86, 0x9e              // BEACO ... and it ends abruptly
        ])
        XCTAssertThrowsError(try AX25Frame(runsOutWhileParsingCallsignsData))
        
        // meets length limit but doesn't have a control field
        let runsOutBeforeReachingControlField = Data([
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // BEACON-0, extension bit 0
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // BEACON-0, extension bit 0
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x61, // BEACON-0, extension bit 1
        ])
        XCTAssertThrowsError(try AX25Frame(runsOutBeforeReachingControlField))

        let runsOutBeforeReachingPIDField = Data([
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x60, // BEACON-0, extension bit 0
            0x84, 0x8a, 0x82, 0x86, 0x9e, 0x9c, 0x61, // BEACON-0, extension bit 1
            0x03, // UID frame type
            // no PID field
        ])
        
        XCTAssertThrowsError(try AX25Frame(runsOutBeforeReachingPIDField))
    }

}
