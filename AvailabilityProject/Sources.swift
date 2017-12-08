

import Foundation
import UIKit

public struct AvailabilityCriteria {
    var arrivalDate: Date
    var departureDate: Date
    var numRooms: Int
    var numAdults: Int
    var numChildren: Int
    var useHonorsPoints: Bool
    var AAAFlag: Bool
    var corporateId: String?
    
    public static func stubCriteria() -> AvailabilityCriteria {
        return AvailabilityCriteria(arrivalDate: Date(), departureDate: Date().addingTimeInterval(60*60*24), numRooms: 1, numAdults: 1, numChildren: 0, useHonorsPoints: false, AAAFlag: false, corporateId: nil)
    }
}

struct Availability {
    var availabilityStatus: String?
    var numericRate: Double?
    var currency: String?
}

struct CtyhocnAvailability: Equatable {
    var ctyhocn: String
    var availability: String?
    public static func ==(lhs: CtyhocnAvailability, rhs: CtyhocnAvailability) -> Bool {
        return lhs.ctyhocn == rhs.ctyhocn &&
            lhs.availability == rhs.availability
    }
}

//////////////////////////////////////////////////////////

protocol Batcher: class {
    
    typealias BatchType = String
    typealias BatchTask = (_ batch: [BatchType], _ completion: @escaping () -> Void) -> Void
    
    var pendingPool: [BatchType]        { get set }
    var batchedPool: Set<BatchType>     { get set }
    var batchLimit: Int                 { get }
    var batchTask: BatchTask            { get }
    
    init(batchLimit: Int, batchTask: @escaping BatchTask)
    
}


extension Batcher {
    
    func extendPool(_ items: [BatchType]) {
        items.forEach {
            if pendingPool.index(of: $0) == nil && batchedPool.index(of: $0) == nil {
                print("Adding \($0) to Pending")
                pendingPool.append($0)
            }
        }
        
        // now start requesting availability
        while let batch = nextBatch() {
            performTask(for: batch)
        }
    }
    
    func drainPool() {
        pendingPool.removeAll()
        batchedPool.removeAll()
    }
    
    func nextBatch() -> [BatchType]? {
        // take the first up to batchLimit elements from self.ctyhocns
        guard !pendingPool.isEmpty else { return nil }
        let maxCount = min(pendingPool.count, batchLimit)
        let slice = pendingPool[0..<maxCount]
        return Array(slice)
    }
    
    func performTask(for batch: [BatchType]) {
        // move the elements from the pending pool to the batched pool
        batch.forEach {
            if let index = self.pendingPool.index(of: $0) {
                print("Removing \($0) from Pending")
                self.pendingPool.remove(at: index)
            }
            print("Adding \($0) to Batched")
            self.batchedPool.insert($0)
        }
        
        print("Sending \(batch)")
        // make the request...
        batchTask(batch) { [weak self] in
            print("Completion: \(batch)")
            // remove the completed ctyhocns from the batched pool
            batch.forEach {
                print("Removing \($0) from Batched")
                self?.batchedPool.remove($0)
            }
        }
    }
    
}

class AvailabilityBatcher: Batcher {
    
    internal var pendingPool: [String] = []
    internal var batchedPool: Set<String> = []
    internal let batchLimit: Int
    internal let batchTask: BatchTask
    
    required init(batchLimit: Int, batchTask: @escaping BatchTask) {
        self.batchLimit = batchLimit
        self.batchTask = batchTask
    }
    
}


////////////////////////////////////////////////////////////

protocol AvailabilityStore {
    func saveAvailability(_ availability: [CtyhocnAvailability])
    func clearAvailability()
}

class AvailabilityManager {
    static var batcher = AvailabilityBatcher(batchLimit: 10) { (batch, completion) in
        // make API call using availabilityCriteria as parameters or whatever
        DispatchQueue.global().async {
            // when batcher gives back availability, save to core data
            AvailabilityManager.store?.saveAvailability([])
            completion()
        }
    }
    static var store: AvailabilityStore?
    static var availabilityCriteria: AvailabilityCriteria?
    
    static func getAvailablility(forCtyhocns ctyhocns: [String], searchCriteria: AvailabilityCriteria?) {
        
        // TODO: only do this if statement if the search request is not nil and is different from our existing one
//        if searchCriteria != nil && searchCriteria != availabilityCriteria {
            // new criteria
            availabilityCriteria = searchCriteria
            
            clearAvailability()
//        }
        
        // give ctyhocns to batcher
        batcher.extendPool(ctyhocns)
    }
    
    static func refreshAvailability(forCtyhocns ctyhocns: [String]) {
        clearAvailability()
                
        // give ctyhocns to batcher
        batcher.extendPool(ctyhocns)
    }
    
    static func clearAvailability() {
        
        // maybe cancel current API calls?
        
        // clear availablity from CD
        store?.clearAvailability()
        
        // tell batcher to cancel requests
        batcher.drainPool()
    }
    
}





