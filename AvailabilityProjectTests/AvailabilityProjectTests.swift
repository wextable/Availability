//
//  AvailabilityProjectTests.swift
//  AvailabilityProjectTests
//
//  Created by Wesley St. John on 12/7/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import XCTest
import UIKit
@testable import AvailabilityProject

class AvailabilityBatcherTests: XCTestCase {
    
    var batcher: AvailabilityBatcher!
    var expectation: XCTestExpectation!
    dynamic var numBatchesCompleted = 0
    
    override func setUp() {
        super.setUp()
        
        numBatchesCompleted = 0
        var numBatchesFired = 0
        
        batcher = AvailabilityBatcher(batchLimit: 2) { (batch, completion) in
            numBatchesFired += 1
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1 + Double(numBatchesFired) * 0.2, execute: {
                
                completion()
                
                self.numBatchesCompleted += 1
                print("Batches completed: \(self.numBatchesCompleted)")
            })
        }
    }
    
    override func tearDown() {
        batcher = nil
        super.tearDown()
    }
    
    func testExtendPoolWithOneBatch() {
        
        expectation = keyValueObservingExpectation(for: self, keyPath: "numBatchesCompleted", handler: { (object, dict) -> Bool in
            return true
        })
        
        batcher.extendPool(["DCAOTHF", "DALMAGI"])
        XCTAssertEqual(batcher.pendingPool, [])
        XCTAssertEqual(batcher.batchedPool, ["DCAOTHF", "DALMAGI"])
        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertEqual(batcher.pendingPool, [])
        XCTAssertEqual(batcher.batchedPool, [])

    }

    
    func testExtendPoolWithMultipleBatches() {
        expectation = keyValueObservingExpectation(for: self, keyPath: "numBatchesCompleted", handler: { (object, dict) -> Bool in
            XCTAssertEqual(self.batcher.pendingPool, [])
            if self.numBatchesCompleted == 1 {
                XCTAssertEqual(self.batcher.batchedPool, ["SFOFHOF"])
            } else if self.numBatchesCompleted == 2 {
                XCTAssertEqual(self.batcher.batchedPool, [])
                return true
            }
            
            return false
        })
        
        batcher.extendPool(["DCAOTHF", "DALMAGI", "SFOFHOF"])
        XCTAssertEqual(batcher.batchedPool, ["DCAOTHF", "DALMAGI", "SFOFHOF"])
        wait(for: [expectation], timeout: 1.0)
    }

    func testDrainPool() {
        batcher.extendPool(["DRAINME", "DRAINMETOO"])
        XCTAssertEqual(batcher.batchedPool, ["DRAINME", "DRAINMETOO"])
        batcher.drainPool()
        XCTAssertEqual(batcher.batchedPool, [])
    }
    
    
}
