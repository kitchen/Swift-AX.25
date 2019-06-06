//
//  CallSignSSIDTests.swift
//  AX.25Tests
//
//  Created by Jeremy Kitchen on 5/29/19.
//  Copyright © 2019 Jeremy Kitchen. All rights reserved.
//

import XCTest
@testable import AX_25

class CallSignSSIDTests: XCTestCase {
    func testRoundTrips() {
        var testCase = CallSignSSID(callSign: "WR0U", ssid: 10)
        XCTAssertEqual("WR0U", CallSignSSID(testCase.field()).CallSign)
        XCTAssertEqual(10, CallSignSSID(testCase.field()).SSID)
        
        testCase = CallSignSSID(callSign: "K1CHN", ssid: 10)

        XCTAssertEqual("K1CHN", CallSignSSID(testCase.field()).CallSign)
        XCTAssertEqual(10, CallSignSSID(testCase.field()).SSID)
        
        testCase = CallSignSSID(callSign: "KE7SIN", ssid: 10)
        XCTAssertEqual("KE7SIN", CallSignSSID(testCase.field()).CallSign)
        XCTAssertEqual(10, CallSignSSID(testCase.field()).SSID)
    }
    
    func testParseField() {
        // WROU-4
        var testCase = CallSignSSID(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08]))
        XCTAssertEqual("WR0U", testCase.CallSign)
        XCTAssertEqual(4, testCase.SSID)
        
        // K1CHN-10
        testCase = CallSignSSID(Data([0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x18]))
        XCTAssertEqual("K1CHN", testCase.CallSign)
        XCTAssertEqual(12, testCase.SSID)
        
        // KE7SIN-6
        testCase = CallSignSSID(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc]))
        XCTAssertEqual("KE7SIN", testCase.CallSign)
        XCTAssertEqual(6, testCase.SSID)
    }
    
    func testFieldOutput() {
        var testCase = CallSignSSID(callSign: "WR0U", ssid: 4)
        XCTAssertEqual(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08]), testCase.field())
        
        testCase = CallSignSSID(callSign: "K1CHN", ssid: 12)
        XCTAssertEqual(Data([0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x18]), testCase.field())
        
        testCase = CallSignSSID(callSign: "KE7SIN", ssid: 6)
        XCTAssertEqual(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc]), testCase.field())
    }
}
