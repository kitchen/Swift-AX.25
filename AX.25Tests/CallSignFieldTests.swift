//
//  CallSignFieldTests.swift
//  AX.25Tests
//
//  Created by Jeremy Kitchen on 6/10/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import XCTest
@testable import AX_25

class CallSignFieldTests: XCTestCase {

    func testField() {
        // WROU-4, extension: yes, seven: no
        var testCase = CallSignField(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x09]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("WR0U", testCase.callSignSSID.CallSign)
            XCTAssertEqual(4, testCase.callSignSSID.SSID)
            XCTAssertTrue(testCase.extensionBit)
            XCTAssertFalse(testCase.sevenBit)
        }
        
        // K1CHN-10, extension: no, seven, yes
        testCase = CallSignField(Data([0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x98]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("K1CHN", testCase.callSignSSID.CallSign)
            XCTAssertEqual(12, testCase.callSignSSID.SSID)
            XCTAssertFalse(testCase.extensionBit)
            XCTAssertFalse(testCase.sevenBit)
        }
        
        // KE7SIN-6 extension: yes, seven: yes
        testCase = CallSignField(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0x8d]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("KE7SIN", testCase.callSignSSID.CallSign)
            XCTAssertEqual(6, testCase.callSignSSID.SSID)
            XCTAssertTrue(testCase.extensionBit)
            XCTAssertTrue(testCase.sevenBit)
        }
        
        // KU0L-9 extension: no, seven: no
        testCase = CallSignField(Data([0x96, 0xaa, 0x60, 0x98, 0x40, 0x40, 0x12]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("KU0L", testCase.callSignSSID.CallSign)
            XCTAssertEqual(9, testCase.callSignSSID.SSID)
            XCTAssertFalse(testCase.extensionBit)
            XCTAssertFalse(testCase.sevenBit)
        }
    }
}
