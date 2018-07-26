//
//  AccelerationRecorder.swift
//  GetHeart Extension
//
//  Created by Admin on 5/9/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import CoreMotion
import WatchKit

class CoreMotionRecorder {
    let motion = CMMotionManager()
    let dataHeading = "date,x_acc,y_acc,z_acc,x_gyro,y_gyro,z_gyro,heart_rate"
    var isRecordingMotion = false
    var recordingFrequency : Double = 1.0/30.0 // 30 Hz
    var sigFigs: Int = 8
    private var motionData: String = ""
    private var timer : Timer?
    var view : InterfaceController
    
    
    /// - parameter viewbox: the parent `InterfaceController`
    init(_ viewbox : InterfaceController) {
        view = viewbox
    }
    /**
     - parameters:
        - viewbox: the parent `InterfaceController`
        - recordingRate: Frequency at which to record
        - dataLength: Length to which data values should be clipped, as a String
    */
    init(_ viewbox : InterfaceController, _ recordingRate: Double, _ dataLength: Int) {
        view = viewbox
        recordingFrequency = recordingRate
        sigFigs = dataLength
    }
    
    /**
     Starts recording acceleration and rotation rate at `recordingFrequency` Hz
     Updates labels with corrosponding values during each tick, and appends values to `motionData`
    */
    func startRecording() {
        if(motion.isDeviceMotionAvailable) {
            isRecordingMotion = true
            motion.deviceMotionUpdateInterval = recordingFrequency
            motion.startDeviceMotionUpdates()
            timer = Timer(fire: Date(), interval: recordingFrequency, repeats: true, block: { (timer) in
                // Get data.
                if let data = self.motion.deviceMotion {
                    let x = String(data.userAcceleration.x.description.prefix(self.sigFigs))
                    let y = String(data.userAcceleration.y.description.prefix(self.sigFigs))
                    let z = String(data.userAcceleration.z.description.prefix(self.sigFigs))
                    let xr = String(data.rotationRate.x.description.prefix(self.sigFigs))
                    let yr = String(data.rotationRate.y.description.prefix(self.sigFigs))
                    let zr = String(data.rotationRate.z.description.prefix(self.sigFigs))
                    // update labels
                    self.view.updateMotionLabel("x", x, true)
                    self.view.updateMotionLabel("y", y, true)
                    self.view.updateMotionLabel("z", z, true)
                    self.view.updateMotionLabel("x", xr, false)
                    self.view.updateMotionLabel("y", yr, false)
                    self.view.updateMotionLabel("z", zr, false)
                    let date = InterfaceController.microsecondsSince1970()
                    self.motionData += ("\(date),\(x),\(y),\(z),\(xr),\(yr),\(zr),\(self.view.heart.newData)\n")
                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
        }
        else {
            isRecordingMotion = false
            view.presentAlert(withTitle: "Error", message: "Device motion unavailable", preferredStyle: .alert, actions: [WKAlertAction(title: "OK", style: .default){}])
        }
        
    }
    /**
     Stops the recording of rotation rate and acceleration.
     Sends the collected data as an Array of Strings to `InterfaceController.motionData`,
     and updates the formatted data variable, `InterfaceController.data`
    */
    func stopRecording() {
        isRecordingMotion = false
        timer?.invalidate()
        timer = nil
        motion.stopDeviceMotionUpdates()
        InterfaceController.motionData = getData(false)
        InterfaceController.data = view.formatData()
        view.updateMotionLabel("x", "---", true)
        view.updateMotionLabel("y", "---", true)
        view.updateMotionLabel("z", "---", true)
        view.updateMotionLabel("x", "---", false)
        view.updateMotionLabel("y", "---", false)
        view.updateMotionLabel("z", "---", false)
    }
    
    /**
     Transforms `motionData` into an array of Strings, splitting by "\n"
     - parameter saveData: determines whether or not to reset existing data, or overwrite.
     - returns: An Array of Strings containing the lines of `motionData`
    */
    func getData(_ saveData: Bool) -> Array<String> {
        let lines = motionData.split(separator: "\n")
        var data : [String] = Array()
        for line in lines {
            data.append(String(line))
        }
        if(!saveData) {
            InterfaceController.data = ""
            motionData = ""
        }
        return data
    }
    
}
