//
//  Downloadder.swift
//  Created by jahan on 2018. 10. 20..
//  Copyright © 2018년 gmkApp. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import UserNotifications

class Downloadder {
    //let sentData = message.body as! NSDictionary
    class func load(url: URL, to localUrl: URL){
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.downloadTask(with: request) {(tempLocalUrl, response, error) in
            if let tempLocalUrl  = tempLocalUrl, error == nil {
                
                print(">>> tempLocalUrl : \(tempLocalUrl) >>> localUrl : \(localUrl)")
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")

                    DispatchQueue.main.async {
                        //appDelegate.sendNotification(title: "다운로드 완료")
                        showAlert(str: "다운로드 완료")
                    }
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                } catch (let writeError){
                    print("error writing file \(localUrl) : \(writeError)")
                    DispatchQueue.main.async {
                        //appDelegate.sendNotification(title: "파일 저장시 발생했습니다")
                        showAlert(str: "파일 저장시 발생했습니다")
                    }
                }
            }else {
                print("Failure: %@", error?.localizedDescription as Any);
                DispatchQueue.main.async {
                    //appDelegate.sendNotification(title: "다운로드시 장애가 발생했습니다")
                    showAlert(str: "다운로드시 장애가 발생했습니다")
                }
            }
            
        }
        task.resume()
    }
    
    class func showAlert(str: String!) {
        let objAlert = UIAlertController(title: "알림", message: str, preferredStyle: UIAlertControllerStyle.alert)
        
        objAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        //self.presentViewController(objAlert, animated: true, completion: nil)
        
        UIApplication.shared.keyWindow?.rootViewController?.present(objAlert, animated: true, completion: nil)
    }
    
}
