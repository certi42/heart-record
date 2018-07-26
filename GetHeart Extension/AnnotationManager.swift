//
//  AnnotationManager.swift
//  GetHeart Extension
//
//  Created by Admin on 6/8/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import WatchKit

class AnnotationManager : WKInterfaceController {
    static let annotation_title = "version,package_type,layer_name,layer_description,annotation_label,start_uutc,end_uutc,channel_names,annotation_description\n"
    var startDate : Int64 = 0
    static var annotations = ""
    var notificationActive = false
    //let buttonColor = UIColor(red: CGFloat(22.0/255.0), green: CGFloat(22.0/255.0), blue: CGFloat(22.0/255.0), alpha: CGFloat(1.0))
    
    @IBOutlet var notificationButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        resetAnnotations()
    }
    
    @IBAction func notificationPressed() {
         if(notificationActive) {
            notificationActive = false
            //notificationButton.setBackgroundColor(buttonColor)
            notificationButton.setTitle("Start event")
            
            presentAlert(withTitle: "Survey", message: "Are you OK?", preferredStyle: .alert, actions: [WKAlertAction(title: "Yes", style: .default, handler: {
                self.createAnnotation(annotation_label: "event response: yes", start_uutc: self.startDate)
            }), WKAlertAction(title: "No", style: .cancel, handler: {
                self.createAnnotation(annotation_label: "event response: no", start_uutc: self.startDate)
            })])
            
         }
         else {
            notificationActive = true
            //notificationButton.setBackgroundColor(UIColor.red)
            notificationButton.setTitle("End event")
            startEvent()
            //notify friends and family
         }
     }
    
    func resetAnnotations() {
        AnnotationManager.annotations = AnnotationManager.annotation_title
        createAnnotation(annotation_label: "start", start_uutc: InterfaceController.microsecondsSince1970())
    }
    
    func createAnnotation(version: String = "1.0", package_type: String = "TimeSeries", layer_name: String = "Layer1", layer_description: String = "", annotation_label: String = "event", start_uutc: Int64, end_uutc: Int64 = InterfaceController.microsecondsSince1970(), channel_names: String = "heart_rate", annotation_description: String = "") {
        AnnotationManager.annotations += "\(version),\(package_type),\(layer_name),\(layer_description),\(annotation_label),\(start_uutc),\(end_uutc),\(channel_names),\(annotation_description)\n"
    }
    
    func startEvent() {
        startDate = InterfaceController.microsecondsSince1970()
    }
    
    static func getAnnotations() -> String {
        defer {
            let date = InterfaceController.microsecondsSince1970()
            AnnotationManager.annotations = AnnotationManager.annotation_title + "\n1.0,TimeSeries,Layer1,,start,\(date),\(date),heart_rate,\n"
        }
        return AnnotationManager.annotations
    }
}
