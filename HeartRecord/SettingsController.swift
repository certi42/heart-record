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
    
    @IBAction func dismissSelf() {
        dismiss(animated: true, completion:{})
    }
    
    @IBAction func openSettings() {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
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
    }
    
    func boolToString(_ arg : Bool) -> String {
        if(arg) {
            return "Yes"
        }
        return "No"
    }
}
