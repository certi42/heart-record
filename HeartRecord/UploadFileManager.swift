//
//  UploadFileManager.swift
//  HeartRecord
//
//  Created by Admin on 5/30/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import Foundation
import MobileCoreServices

class UploadFileManager {
    
    init() {
        let request = createRequest()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                // handle error here
                print(error!)
                return
            }
            do {
                if let responseDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    print("success == \(responseDictionary)")
                    
                }
            } catch {
                print(error)
                
                let responseString = String(data: data!, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
            }
        }
        task.resume()
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
    
    func uploadFile(url: URL) {
        var uploadData : Data = Data()
        do {
            uploadData = try Data(contentsOf: url)
        }
        catch {
            print(error)
        }
        //https://158.130.14.40/post
        //https://httpbin.org/post
        let url = URL(string: "https://ptsv2.com/t/gp9xn-1527706659/post")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/csv", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            print(response ?? "no response")
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    print ("server error")
                    return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/zip",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
    
    
    
    func createRequest () -> URLRequest {
        let param: [String : String] = [:]
        let boundary = generateBoundaryString()
        
        let url = URL(string: "URl")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        //let path1 = NSBundle.mainBundle().pathForResource("voice", ofType: "png") as String!
        request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "voice", paths: ["pathURl"], boundary: boundary)
        
        return request
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, paths: [String]?, boundary: String) -> Data {
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        if paths != nil {
            for path in paths! {
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent
                var data = Data()
                do {
                    data = try Data(contentsOf: url)
                }
                catch {
                    print(error)
                }
                let mimetype = mimeTypeForPath(path: path)
                
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
                body.append("Content-Type: \(mimetype)\r\n\r\n")
                body.append(data)
                body.append("\r\n")
            }
        }
        
        body.append("--\(boundary)--\r\n")
        return body as Data
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    
    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }
}

extension NSMutableData {
    func append(_ string: String) {
        let data = string.data(
            using: String.Encoding.utf8,
            allowLossyConversion: true)
        append(data!)
    }
}
