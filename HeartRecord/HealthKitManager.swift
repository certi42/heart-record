//
//  HealthKitManager.swift
//  HeartRecord
//
//  Created by Admin on 5/9/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitManager: NSObject {
    
    static let healthKitStore = HKHealthStore()
    
    /// Prompts the user to allow the application to read heart-rate data.
    static func authorizeHealthKit() {
        let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        healthKitStore.requestAuthorization(toShare: [], read: healthKitTypes) { _, _ in }
    }
}
