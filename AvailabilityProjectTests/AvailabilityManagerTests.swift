//
//  AvailabilityManagerTests.swift
//  AvailabilityProjectTests
//
//  Created by Wesley St. John on 12/8/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import XCTest
@testable import AvailabilityProject

/*
 protocol AvailabilityStore {
     func saveAvailability(_ availability: [CtyhocnAvailability])
     func clearAvailability()
 }
 */



class AvailabilityManagerTests: XCTestCase {
    
    class stubStore: AvailabilityStore {
        var stubData: [CtyhocnAvailability] = []
        func saveAvailability(_ availability: [CtyhocnAvailability]) {
            stubData.append(contentsOf: availability)
        }
        func clearAvailability() {
            stubData.removeAll()
        }
        func stubAvailability(forCtyhocns ctyhocns: [String]) -> [CtyhocnAvailability]? {
            return ctyhocns.map {
                CtyhocnAvailability(ctyhocn: $0, availability: $0+" is available")
            }
        }
    }
    
    var manager: AvailabilityManager!
    var batcher: AvailabilityBatcher!
    let store = stubStore()
    var savedData: [CtyhocnAvailability] {
        return store.stubData
    }
    var criteria: AvailabilityCriteria!
    var expectation: XCTestExpectation!
    dynamic var numBatchesCompleted = 0
    
    override func setUp() {
        super.setUp()
        
        AvailabilityManager.store = store
        
        numBatchesCompleted = 0
        var numBatchesFired = 0
        
        AvailabilityManager.batcher = AvailabilityBatcher(batchLimit: 2) { (batch, completion) in
            numBatchesFired += 1
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1 + Double(numBatchesFired) * 0.2, execute: {
                
                
                if let avail = self.store.stubAvailability(forCtyhocns: batch) {
                    AvailabilityManager.store?.saveAvailability(avail)
                }
                
                completion()
                self.numBatchesCompleted += 1
            })
        }
        
        
    }
    
    override func tearDown() {
        store.clearAvailability()
        super.tearDown()
    }
    
    func testGetInitialAvailability() {
        expectation = keyValueObservingExpectation(for: self, keyPath: "numBatchesCompleted", expectedValue: 2)
        AvailabilityManager.getAvailablility(forCtyhocns: ["DALMAGI", "DCAOTHF", "SFOFOHF"], searchCriteria: AvailabilityCriteria.stubCriteria())
        XCTAssertTrue(savedData.isEmpty)
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(savedData.count, 3)
        guard let ca1 = savedData.first,
            let ca3 = savedData.last else {
                XCTFail("Didn't save availability")
                return
        }
        XCTAssertEqual(ca1.ctyhocn, "DALMAGI")
        XCTAssertEqual(ca1.availability, "DALMAGI is available")
        XCTAssertEqual(ca3.ctyhocn, "SFOFOHF")
        XCTAssertEqual(ca3.availability, "SFOFOHF is available")
    }

    func testRefreshAvailability() {
        expectation = keyValueObservingExpectation(for: self, keyPath: "numBatchesCompleted", expectedValue: 2)
        AvailabilityManager.getAvailablility(forCtyhocns: ["DALMAGI", "DCAOTHF", "SFOFOHF"], searchCriteria: AvailabilityCriteria.stubCriteria())
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(savedData.count, 3)
        
        numBatchesCompleted = 0
        expectation = keyValueObservingExpectation(for: self, keyPath: "numBatchesCompleted", expectedValue: 1)
        AvailabilityManager.refreshAvailability(forCtyhocns: ["HARRY", "POTTER"])
        XCTAssertTrue(savedData.isEmpty)
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(savedData.count, 2)
        guard let ca1 = savedData.first,
            let ca2 = savedData.last else {
                XCTFail("Didn't save availability")
                return
        }
        XCTAssertEqual(ca1.ctyhocn, "HARRY")
        XCTAssertEqual(ca1.availability, "HARRY is available")
        XCTAssertEqual(ca2.ctyhocn, "POTTER")
        XCTAssertEqual(ca2.availability, "POTTER is available")
    }
}
