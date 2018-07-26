//
//  InterfaceController.swift
//  GetHeart Extension
//
//  Created by Admin on 5/9/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {  }
    func session(_ session : WCSession, didFinishWithError: Error) {  }
    /// The heart beat recording object
    var heart : HeartBeatRecorder! = nil
    /// The motion recording object - cmr stands for CoreMotionRecorder
    var cmr : CoreMotionRecorder! = nil
    /// An object which records annotation for events which occur during recording
    //static var notify : AnnotationManager! = nil
    /// An array which stores finished motion data
    static var motionData: [String] = []
    static var heartData: [String] = []
    // Data which has been formatted as a .csv
    static var data = ""
    /// Length, in characters, of the data to be sent to iPhone.
    /// This value is also set in `sendDataPressed`
    var parcelLength = 100000
    /// the index of the current chunk of data being sent to the iPhone
    static var parcelIndex = 0
    /// controls automatic offloading of data to iPhone
    var postTimer : Timer! = nil
    /// automatic offloading interval in seconds. 300 seconds is 5 minutes
    let postInterval = 300.0
    /// date of start of current recording sessino
    var startDate : Date = Date()
    /// whether or not notification is currently active
    //var notificationActive = false
    /// locally stored annotations
    //static var annotations = ""
    
    //MARK: Properties
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var recordButton: WKInterfaceButton!
    @IBOutlet var interfaceTimer: WKInterfaceTimer!
    //@IBOutlet var notificationButton: WKInterfaceButton!
    
    @IBOutlet var xAccLabel: WKInterfaceLabel!
    @IBOutlet var yAccLabel: WKInterfaceLabel!
    @IBOutlet var zAccLabel: WKInterfaceLabel!
    
    @IBOutlet var xRotationLabel: WKInterfaceLabel!
    @IBOutlet var yRotationLabel: WKInterfaceLabel!
    @IBOutlet var zRotationLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        heart = HeartBeatRecorder(self)
        cmr = CoreMotionRecorder(self)
        //InterfaceController.notify = AnnotationManager()
        setTitle("HeartRecord")
        if(!WCSession.default.isReachable) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    /*@IBAction func notificationPressed() {
        if(notificationActive) {
            notificationActive = false
            notificationButton.setBackgroundColor(UIColor.darkGray)
            notificationButton.setTitle("I'm having a seizure")
            presentAlert(withTitle: "Survey", message: "Are you OK?", preferredStyle: .alert, actions: [WKAlertAction(title: "Yes", style: .default, handler: {}), WKAlertAction(title: "No", style: .cancel, handler: {})])
            //create annotation
            InterfaceController.notify.createAnnotation(start_uutc: InterfaceController.notify.startDate)
        }
        else {
            notificationActive = true
            notificationButton.setBackgroundColor(UIColor.red)
            notificationButton.setTitle("Seizure complete")
            InterfaceController.notify.startEvent()
            //notify friends and relatives
        }
    }*/
    
    /// Deletes all currently stored data in the `InterfaceController`
    @IBAction func menuDeleteData() {
        InterfaceController.data = ""
        InterfaceController.motionData = []
        //InterfaceController.heartData = []
    }
    
    /// Starts or stops recording
    @IBAction func toggleRecording() {
        //stop recording
        if(heart.isRecording) {
            recordButton.setTitle("Start")
            heart.stopRecording()
            cmr.stopRecording()
            interfaceTimer.stop()
            interfaceTimer.setDate(Date())
            postTimer.invalidate()
            postTimer = nil
        }
        //start recording
        else {
            recordButton.setTitle("Stop")
            heart.startRecording()
            cmr.startRecording()
            startDate = Date()
            interfaceTimer.setDate(startDate)
            interfaceTimer.start()
            postTimer = Timer(fire: startDate, interval: postInterval, repeats: true, block: { timer in
                InterfaceController.motionData = self.cmr.getData(false)
                if(self.formatData().count > 1000) {
                    self.sendData(true)
                }
            })
            RunLoop.current.add(postTimer, forMode: .defaultRunLoopMode)
        }
      
    }

    /// Begins to send data to iPhone
    @IBAction func sendDataPressed() {
        sendData(false)
    }
    
    /**
     Begins the process of sending all of the data currently stored
     on the watch to the paired phone.
     - parameter isAuto: Specifies whether or not to have the iPhone
     automatically send the data to the server
    */
    func sendData(_ isAuto : Bool) {
        InterfaceController.data = formatData() + "#ANNOTATIONS\n" + AnnotationManager.getAnnotations()//InterfaceController.notify.getAnnotations()
        
        InterfaceController.parcelIndex = 0
        parcelLength = 100000
        sendDataChunks(i: InterfaceController.parcelIndex, postData: isAuto)
    }
    
    /**
     Sends a string of characters to the iPhone app, with length specified by parcelLength
     which starts off at 100000 characters long. If a `PayloadTooLarge` error is thrown
     `parcelLength` is divided by 2, and the transfer is reattempted.
 
     Message title is "chunk {i}", and will include in "final" if this message contains the end
     of the data. If the data is supposed to be automatically sent to the server by the iPhone,
     the title will end in "post"
     - parameter i: the number of the chunk to be sent. This is used in the creation of the message title
    */
    func sendDataChunks(i : Int, postData : Bool) {
        if(WCSession.default.isReachable && InterfaceController.data.count > 0) {
            var title = "chunk \(i) "
            if(InterfaceController.data.count <= parcelLength) {
                title += "final "
            }
            if(postData) {
                title += "post"
            }
            let package = String(InterfaceController.data.prefix(parcelLength))
            InterfaceController.data = String(InterfaceController.data.suffix(InterfaceController.data.count-package.count))
            
            WCSession.default.sendMessage([title: package], replyHandler: nil, errorHandler: { error in
                DispatchQueue.main.async {
                    //self.presentAlert(withTitle: "Error sending data", message: "\(error.localizedDescription)\nSize: \(self.toKB(package.count))", preferredStyle: .alert, actions: [WKAlertAction(title:"OK",style:.cancel,handler: {})])
                    InterfaceController.data = package + InterfaceController.data
                    self.parcelLength /= 2
                    self.sendDataChunks(i: i, postData: postData)
                }
            })
        }
        else {
            if(!WCSession.default.isReachable) {
                presentAlert(withTitle: "Unable to send data", message: "Failed to send recorded data to iPhone", preferredStyle: .alert, actions: [WKAlertAction(title:"OK",style:.cancel,handler: {})])
            }
        }
    }
    /**
     When a message is received from the iPhone app, play a click.
    
     If the message title is "Received", which indicates that the most recent
     data from sendDataChunks() was received, send the next chunk
     */
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        WKInterfaceDevice().play(.click)
        let title = message.keys.first!
        if(title == "Received") {
            InterfaceController.parcelIndex += 1
            //print(message[title].debugDescription)
            let post = message[title].debugDescription.contains("post")
            sendDataChunks(i: InterfaceController.parcelIndex, postData: post)
        }
    }
    /**
     Formats motion and heart-rate data into a csv format, with a header and values
     for all data types.
     - returns: A string with data formatted as a csv
    */
    func formatData() -> String {
        var output = cmr.dataHeading + "\n"
        for line in InterfaceController.motionData {
            output += line + "\n"
         }
        return output
    }
    
    /// Updates the `heartRateLabel` with the new values for heart-rate
    func updateHeartLabel(heartRate: String) {
        updateLabel(heartRateLabel, "Heart Rate: \(heartRate) bpm")
    }
    
    /**
    Updates the specified motion label with the new value, formatted like
     "x: 1.13253 g" or "z: -0.24125 rad/s"
    - parameters:
        - dir: the direction (x, y, or z) of the data value
        - value: the new data value to be assigned
        - isAcc: specifies whether the new value is for acceleration.
        Will be true if the value is acceleration, and false otherwise
    */
    func updateMotionLabel(_ dir : String, _ value : String, _ isAcc: Bool) {
        // There's probably a much cleaner way to program this, but I don't know what it is
        // Also apparently Swift doesn't require 'break' in switch blocks
        var label : WKInterfaceLabel? = nil
        switch dir {
            case "x":
                if(isAcc) {
                    label = xAccLabel
                } else {
                    label = xRotationLabel
                }
                break
            case "y":
                if(isAcc) {
                    label = yAccLabel
                } else {
                    label = yRotationLabel
                }
                break
            case "z":
                if(isAcc) {
                    label = zAccLabel
                } else {
                    label = zRotationLabel
                }
                break
            default:
                print("Unknown direction \(dir)")
                return
        }
        var units : String
        if(isAcc) {
            units = "g"
        } else {
            units = "rad/s"
        }
        updateLabel(label, "\(dir): \(value) \(units)")
    }
    
    /**
     Updates a label with the given string. Checks that the label is not
     `nil` for increased safety.
     - parameters:
        - label: the label whose value should be updated
        - value: the new text for the label
     */
    func updateLabel(_ label : WKInterfaceLabel!, _ value : String) {
        //if label != nil
        if let l = label {
            l.setText(value)
        }
    }
    
    /**
     Formats Date.timeIntervalSince1970 to microseconds
     - returns: the number of microseconds which have passed since January 1, 1970 UTC
     */
    static func microsecondsSince1970() -> Int64 {
        return Int64(round(Date().timeIntervalSince1970*1000000))
    }
    /**
     Divides the current value by 1024 and rounds to 3 decimal places
     Used to convert bytes to kilobytes
     - parameter size: the Int to be converted
     - returns: the new value, divided and rounded
     - note: I do know that kilobytes are usually 1000 bytes, but
     I'm doing it this way
    */
    func toKB(_ size: Int) -> String {
        return "\(round(Double(size)/1.024)/1000.0) KB"
    }
}
