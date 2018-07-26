//
//  SettingsController.swift
//  HeartRecord
//
//  Created by Admin on 6/18/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import UIKit

class SettingsController : UIViewController {
    
    @IBOutlet weak var serverAddressLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var includeDateLabel: UILabel!
    @IBOutlet weak var saveDataLabel: UILabel!
    @IBOutlet weak var hapticLabel: UILabel!
    @IBOutlet weak var patientIdLabel: UILabel!
    
    /// close the settings window and return to main screen
    @IBAction func dismissSelf() {
        dismiss(animated: true, completion:{})
    }
    
    /// open the app's pane in the Settings app
    @IBAction func openSettings() {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    /// sets labels to corrosponding values from settings pane
    override func viewDidLoad() {
        let defaults = UserDefaults.standard;
        if let address = defaults.string(forKey: "server_preference") {
            serverAddressLabel.text = "Server Address: " + address
        }
        includeDateLabel.text = "Include date: \(boolToString(defaults.bool(forKey: "date_filename_preference")))"
        if let filename = defaults.string(forKey: "name_preference") {
            filenameLabel.text = "Filename: " + filename
        }
        saveDataLabel.text = "Save Data: \(boolToString(defaults.bool(forKey: "save_data_preference")))"
        hapticLabel.text = "Haptic Feedback: \(boolToString(defaults.bool(forKey: "haptic_preference")))"
        if let patientID = defaults.string(forKey: "patient_id_preference") {
            patientIdLabel.text = "Patient ID: " + patientID
        }
    }
    
    /**
     Converts a Bool into a "readable" String.
     - true -> Yes
     - false -> No
     - parameter arg: the Bool to be converted
     - returns: either "Yes" or "No" based on the input argument
    */
    func boolToString(_ arg : Bool) -> String {
        if(arg) {
            return "Yes"
        }
        return "No"
    }
}
