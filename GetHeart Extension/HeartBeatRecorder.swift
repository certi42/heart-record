//
//  HeartBeatRecorder.swift
//  GetHeart Extension
//
//  Created by Admin on 5/11/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import HealthKit

class HeartBeatRecorder: NSObject, HKWorkoutSessionDelegate {
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from : "count/min")
    var isRecording = false
    //let dataHeading = "date,heart_rate"
    //var heartData = ""
    var newData = "-1"
    var workoutSession : HKWorkoutSession!
    var currentQuery : HKQuery!
    var view : InterfaceController
    init(_ viewbox: InterfaceController) {
        view = viewbox
        super.init()
        guard HKHealthStore.isHealthDataAvailable() == true else {
            view.heartRateLabel.setText("not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            view.heartRateLabel.setText("display not allowed")
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.view.heartRateLabel.setText("HealtKit not authorized")
                print("display not allowed")
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutStarted(date)
        case .ended:
            workoutEnded(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Error : \(error)")
    }
    /// Creates streaming query for heart rate data
    func workoutStarted(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currentQuery = query
            healthStore.execute(query)
        } else {
            view.updateHeartLabel(heartRate: "can't start")
        }
    }
    /// Stops streaming query, resets the heart-rate label and updates InterfaceController data
    func workoutEnded (_ date : Date) {
        healthStore.stop(self.currentQuery!)
        view.updateHeartLabel(heartRate: "---")
        workoutSession = nil
        //InterfaceController.heartData = getData(false)
        //InterfaceController.data = view.formatData()
    }

    /// Starts recording heart-rate
    func startRecording() {
        isRecording = true
        startWorkout()
    }
    /// Stops recording heart-rate
    func stopRecording() {
        isRecording = false
        if let workout = workoutSession {
            healthStore.end(workout)
        }
    }
    /// Starts workout to speed up heart-rate updates
    func startWorkout() {
        // workout already started
        if(workoutSession != nil) {
            return
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .crossTraining
        workoutConfiguration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
            workoutSession.delegate = self
        }
        catch {
            fatalError("Failure to start HKWorkoutSession")
        }
        healthStore.start(workoutSession)
        
    }
    /// Creates streaming query for heart-rate samples
    /// - parameter workoutStartDate: the Date when the workout started
    /// - returns the streaming query
    func createHeartRateStreamingQuery(_ workoutStartDate : Date) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])

        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    /**
     Handles heart-rate updates, and updates heart-rate label
     - parameter samples: the new sample(s)
    */
    func updateHeartRate(_ samples : [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        guard let sample = heartRateSamples.first else {
            return
        }
        newData = "\(Int(sample.quantity.doubleValue(for: self.heartRateUnit)))"
        //heartData += "\(InterfaceController.getFormattedDate(Date())), \(newData),\n"
        view.updateHeartLabel(heartRate: newData)
    }
    /**
     Transforms `heartData` into an array of Strings, splitting by "\n"
     - parameter saveData: determines whether or not to reset existing data, or overwrite.
     - returns: An Array of Strings containing the lines of `heartData`
     
    func getData(_ saveData: Bool) -> Array<String> {
        var data : [String] = Array()
        for line in heartData.split(separator: "\n") {
            data.append(String(line))
        }
        if(!saveData) {
            InterfaceController.data = ""
            heartData = ""
            newData = "-1"
        }
        return data
    }*/
}
