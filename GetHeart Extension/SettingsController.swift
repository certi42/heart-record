//
//  SettingsController.swift
//  GetHeart Extension
//
//  Created by Admin on 6/18/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import WatchKit

class SettingsController : WKInterfaceController {
    
    @IBOutlet var autoPostLabel: WKInterfaceLabel!
    @IBOutlet var postIntervalLabel: WKInterfaceLabel!
    @IBOutlet var recordingFreqLabel: WKInterfaceLabel!
    
   

    override func willActivate() {
        super.willActivate()
        
        //update labels
        autoPostLabel.setText("Auto Post: \(boolToString(ExtensionDelegate.postAuto))")
        postIntervalLabel.setText("Post Interval: \(Int(ExtensionDelegate.postInterval)) s")
        recordingFreqLabel.setText("Recording Freq: \(Int(round(ExtensionDelegate.recordingFreq))) Hz")
    }
    
    func boolToString(_ arg : Bool) -> String {
        if(arg) {
            return "Yes"
        }
        return "No"
    }
    
}
