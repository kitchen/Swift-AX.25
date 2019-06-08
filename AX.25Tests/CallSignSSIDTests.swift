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
    struct roundTripTestCase {
        let CallSign: String
        let SSID: UInt8
    }
    func testRoundTrips() {
        let testCases = [
            roundTripTestCase(CallSign: "WR0U", SSID: 10),
            roundTripTestCase(CallSign: "K1CHN", SSID: 10),
            roundTripTestCase(CallSign: "KE7SIN", SSID: 10)
        ]
        
        for testCase in testCases {
            guard let memberWise = CallSignSSID(callSign: testCase.CallSign, ssid: testCase.SSID) else {
                XCTFail()
                continue
            }
            guard let dataWise = CallSignSSID(memberWise.field()) else {
                XCTFail()
                continue
            }
            
            XCTAssertEqual(testCase.CallSign, dataWise.CallSign)
            XCTAssertEqual(testCase.SSID, dataWise.SSID)
            XCTAssertEqual(memberWise, dataWise)
        }
    }
    
    func testParseField() {
        // WROU-4
        var testCase = CallSignSSID(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("WR0U", testCase.CallSign)
            XCTAssertEqual(4, testCase.SSID)
        }
        
        // K1CHN-10
        testCase = CallSignSSID(Data([0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x18]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("K1CHN", testCase.CallSign)
            XCTAssertEqual(12, testCase.SSID)
        }
        
        // KE7SIN-6
        testCase = CallSignSSID(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc]))
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual("KE7SIN", testCase.CallSign)
            XCTAssertEqual(6, testCase.SSID)
        }
    }
    
    func testFieldOutput() {
        var testCase = CallSignSSID(callSign: "WR0U", ssid: 4)
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08]), testCase.field())
            let roundTrip = CallSignSSID(testCase.field())
            XCTAssertNotNil(roundTrip)
            if let roundTrip = roundTrip {
                XCTAssertEqual(4, roundTrip.SSID)
            }

        }
        
        testCase = CallSignSSID(callSign: "K1CHN", ssid: 12)
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual(Data([0x96, 0x62, 0x86, 0x90, 0x9c, 0x40, 0x18]), testCase.field())
        }
        
        testCase = CallSignSSID(callSign: "KE7SIN", ssid: 6)
        XCTAssertNotNil(testCase)
        if let testCase = testCase {
            XCTAssertEqual(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc]), testCase.field())
        }
    }
    
    func testDataSlice() {
        let testCase = Data([0x00, 0x00, 0xff, 0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08, 0xff, 0x00, 0x00])
        guard let testCaseFirstIndex = testCase.firstIndex(of: 0xff) else {
            XCTFail()
            return
        }
        let testCaseSlice = testCase.suffix(from: testCaseFirstIndex + 1).prefix(while: { $0 != 0xff })
        XCTAssertEqual(Data([0xae, 0xa4, 0x60, 0xaa, 0x40, 0x40, 0x08]), testCaseSlice)
        
        let testCaseObject = CallSignSSID(testCaseSlice)
        XCTAssertNotNil(testCaseObject)
        if let testCaseObject = testCaseObject {
            XCTAssertEqual("WR0U", testCaseObject.CallSign)
            XCTAssertEqual(4, testCaseObject.SSID)
        }
    }
    
    func testAnotherDataSlice() {
        let testCase = Data([0x00, 0x00, 0xff, 0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc, 0xff, 0x00, 0x00])
        guard let testCaseFirstIndex = testCase.firstIndex(of: 0xff) else {
            XCTFail()
            return
        }
        let testCaseSlice = testCase.suffix(from: testCaseFirstIndex + 1).prefix(while: { $0 != 0xff })
        XCTAssertEqual(Data([0x96, 0x8a, 0x6e, 0xa6, 0x92, 0x9c, 0xc]), testCaseSlice)
        
        let testCaseObject = CallSignSSID(testCaseSlice)
        XCTAssertNotNil(testCaseObject)
        if let testCaseObject = testCaseObject {
            XCTAssertEqual("KE7SIN", testCaseObject.CallSign)
            XCTAssertEqual(6, testCaseObject.SSID)
        }
    }
    
    func testInvalidCases() {
        XCTAssertNil(CallSignSSID(Data([])))
        XCTAssertNil(CallSignSSID(Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])))
        XCTAssertNil(CallSignSSID(callSign: "K1CHN", ssid: 42))
    }
}
