//
//  FileManager.swift
//  HeartRecord
//
//  Created by Admin on 5/11/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import MessageUI
import Zip
import UserNotifications

class SendFileManager : NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UNUserNotificationCenterDelegate {
    
    var view : ViewController
    var useDate : Bool
    var filename : String
    var patientID : String
    var emailAddresses = ["bsiderowf@gmail.com"]
    var serverAddress = ""
    //"http://158.130.14.40"
    /// Creates a `FileManager` object
    /// - parameter viewbox: The parent `ViewController`
    /// - parameter server: the server address to which data should be uploaded
    init(_ viewbox: ViewController, server: String = "http://borel.seas.upenn.edu:3456", includeDate: Bool = true, file : String = "data", patient_id : String = "0") {
        view = viewbox
        serverAddress = server
        useDate = includeDate
        filename = file
        patientID = patient_id
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    /**
     Presents a UIActivityViewController, which allows the user to share
     the data, which has been compressed into a .zip format
     - parameter data: the data to be shared, in a String format
     */
    func sendFile(data: String) {
        let objectsToShare = [createFile(csvText: data)]
        let activityController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        view.present(activityController, animated: true, completion: nil)
    }
    
    /*func sendFileRaw(data : NSData) {
        let activityController = UIActivityViewController(activityItems: data.., applicationActivities: nil)
        view.present(activityController, animated: true, completion: nil)
    }*/
    func sendFileURL(url: URL) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        view.present(activityController, animated: true, completion: nil)
    }
    
    /**
     Allows the user to email data to an email address.
     The default subject line is "Apple Watch data at `Date`",
     and the default email addresses are specified in the
     `addresses` variable as elements of an Array
     - parameter data: The data, as a String, to be emailed
    */
    func emailFile(data : String) {
        if(MFMailComposeViewController.canSendMail()) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(emailAddresses)
            mailComposer.setSubject("Apple Watch data at \(getShortDate(Date()))")
            do {
                try mailComposer.addAttachmentData(NSData(contentsOf: createFile(csvText: data)) as Data, mimeType: "application/zip", fileName: "data.zip")
            }
            catch {
                print("Faild to attach file")
                print("\(error)")
            }
            view.present(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        view.dismiss(animated: true, completion: nil)
    }
    
    /**
     Takes a csv formatted String, saves it to a file, and compresses it into a
     .zip file.
     - parameter csvText: The text, as a string, to be made into a .csv file
     - returns: the URL to the zipped file
    */
    func createFile(csvText: String) -> URL {
        var dateString = ""
        if(useDate) {
            dateString = " \(getShortDate(Date()))"
        }
        let compiledName = "\(filename)\(dateString).csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(compiledName)
        var zipFilePath : URL! = nil
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            zipFilePath = try Zip.quickZipFiles([path!], fileName: "archive") // Zip
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        return zipFilePath!
    }
    
    
    func createFileUnzipped(csvText: String) -> URL {
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("data.csv")
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        return path!
    }
    
    func uploadFile(fileURL: URL) {
        var uploadData : Data = Data()
        do {
            uploadData = try Data(contentsOf: fileURL)
        }
        catch {
            print(error)
        }
        //http://158.130.14.40
        let url = URL(string: serverAddress)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/csv", forHTTPHeaderField: "Content-Type")
        request.addValue(patientID, forHTTPHeaderField: "Patient-ID")
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            var inView = false
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .active {
                    inView = true
                }
            }
            if let error = error {
                print ("error: \(error)")
                if(inView) {
                    self.showErrorMessage(title: "Error sending data", message: error.localizedDescription)
                }
                else {
                    //show notification
                    self.createNotification(title: "Error sending data", message: error.localizedDescription)
                }
                return
            }
            //print(response ?? "no response")
            guard let response = response as? HTTPURLResponse else {
                print ("server error")
                if(inView) {
                    self.showErrorMessage(title: "Server error", message: "The server returned an error")
                }
                else {
                    //show notification
                    self.createNotification(title: "Server error", message: "The server returned an error")
                }
                return
            }
            if(!(200...299).contains(response.statusCode)) {
                let message = "Error code: \(response.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))"
                if(inView) {
                    self.showErrorMessage(title: "Server error", message: message)
                }
                else{
                    //show notification
                    self.createNotification(title: "Server error", message: message)
                }
                return
            }

            if let mimeType = response.mimeType,
                mimeType == "text/csv",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                    print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
    
    /**
     Formats a given date to the format "yyyy-MM-dd HH:mm:ss"
     - parameter longDate: the `Date` to be formatted
     - returns: the new date
     */
    func getShortDate(_ longDate: Date) -> String {
        let df = DateFormatter()
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = df.string(from: longDate)
        return date
    }
    
    /**
     Presents a popup alert with the specified message and title
     - parameter title: the title to be displayed in the popup
     - parameter message: the message to be displayed in the popup
    */
    func showErrorMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.view.present(alert, animated: true)
    }
    /**
     Sends a notification with the default sound, and the specified title and message
     - parameter title: the title to be displayed in the notification
     - parameter message: the message to be displayed in the notification
     */
    func createNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default()
        let notification = UNNotificationRequest(identifier: "http_notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(notification, withCompletionHandler: { error in
            if let error = error {
                print(error)
            }
        })
    }
    
    func cleanData(data : String) {
        let data_line_re = "[\\d.,-]{73}"
        let ann_line_re = "[\\w.,: ]{60,100}"
        let date_header = "date,x_acc,y_acc,z_acc,x_gyro,y_gyro,z_gyro"
        let ann_header = "version,package_type,layer_name,layer_description,annotation_label,start_uutc,end_uutc,channel_names,annotation_description"
        let ann_tag = "#ANNOTATIONS"
        var lines : [String] = [""]
        for line in data.split(separator: "\n") {
            lines.append(String(line))
        }
        lines.reverse()
        
        var i = 0
        for line in lines {
            if(!matches(for: data_line_re, in: line) && !matches(for: ann_line_re, in: line) && !(line==date_header) && (line==ann_header) && (line==ann_tag)) {
                lines.remove(at:i)
            }
            i += 1
        }
    }
    
    func matches(for regex: String, in text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.count > 0
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }

    
}
