//
//  AppDelegate.swift
//  Created by jahan on 2018. 10. 3..
//  Copyright © 2018년 gmkApp. All rights reserved.
//
/*
 File: MixerHostAppDelegate.m
 Abstract: Application delegate.
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var naviController : UINavigationController?
    var processPool : Any?
    let server_url:String? = "https://www.gmkapp.com"       //루트 URL
    //let server_url:String? = "http://192.168.43.30:8080"       //루트 URL
    let main_url:String? = "/mobile/main/main.do"           // 메인 URL
    let login_url:String? = "/mobile/login.do"              //로그인 URL
    let version_url:String? = "https://www.gmkapp.com/api/mobile/auth/selectAppVersion.json" // app 버젼관리 URL
    var sub_url:String? = ""                                //호출 URL (루트 URL + 서브 URL)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        setPreferences("isLuanch", nvalue: "0")
        
        // Override point for customization after application launch.
        URLProtocol.registerClass(MyURLProtocol.self)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 10.0, *) {
            self.naviController = UINavigationController(rootViewController: ViewController())
        } else {
            // Fallback on earlier versions
        }
        self.naviController?.navigationBar.isHidden = true
        self.window?.rootViewController = self.naviController
        self.window?.makeKeyAndVisible()
        
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().backgroundColor = UIColor.black
        
        
         /*
         # 현재 푸시토큰관련 정보는 GM사내앱에서는 사용하지 않는다고 한다. 그래서 막아놓았음 향후 푸시가 필요할 경우 아래 코드 주석 삭제해 줘야 함
         push 관련 정의 코드 (해당 코드 정의가 없으면 push 를 못받는다)
        */
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        
        application.registerUserNotificationSettings(pushNotificationSettings)
        application.registerForRemoteNotifications()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (authorized, error) in
                if !authorized {
                    print("App is useless becase you did not allow notification")
                }
            })
            UNUserNotificationCenter.current().delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories:nil)
            
            application.registerUserNotificationSettings(settings)
        }
        
        
        /* 앱이 꺼진 상태에서 PUSH 클릭했을 때 */
        //if launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil {
        //    setPreferences("isBackgroundPushClick", nvalue: "true")
        //    setPreferences("isBackgroundFlag", nvalue: "true")
        //}
        
        //let remoteNotif = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: Any]
        //if remoteNotif != nil {
        //    let aps = remoteNotif!["aps"] as? [String:AnyObject]
        //    NSLog("\n Custom: \(String(describing: aps))")
        //}
        //else {
        //    NSLog("//////////////////////////Normal launch")
        //}
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        if(getPreferences("tokenId")==""){
            setPreferences("tokenId", nvalue: token)
        }
        
    }
    
    
    /*
     // Downloadder.swift 에서 해당 함수 호출하여 ViewController.swift로 callback 던지게 끔 만든 인터페이스
    func sendNotification(title: String){
        // 앱이 켜진 상태에서 PUSH 클릭 - 새로운 뷰를 호출한다
        if let rootViewController = window?.rootViewController as? UINavigationController {
            if #available(iOS 10.0, *) {
                if let viewController = rootViewController.viewControllers.first as? ViewController {
                    viewController.sendResponseString("파일을 저장했습니다.", callback: viewController.sentData!["callbackFunc"] as? String)
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    */
    
    /*
     네이티브 값 저장
     setPreferences("key",nvalue:"value")
     */
    func setPreferences(_ nkey:String!,nvalue:String!){
        UserDefaults.standard.set(nvalue, forKey: nkey)
    }
    /*
     네이티브 저장 값 가져오기
     getPreferences("key");
     */
    func getPreferences(_ nkey:String!) -> String{
        var val = UserDefaults.standard.string(forKey: nkey!)
        if(val==nil){
            val = ""
        }
        return val!
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        //setPreferences("userId", nvalue: "")
        //setPreferences("password",nvalue:"");
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            print ("Message Closed")
            setPreferences("isBackgroundFlag", nvalue: "true")
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print ("App is Open")
            setPreferences("isBackgroundFlag", nvalue: "false")
        }
        
        
        
        if let notification = response.notification.request.content.userInfo as? [String:AnyObject] {
            let url = parseRemoteNotification(notification: notification)
            //print(">>> userNotificationCenter url \(url as String?))")
            sub_url = server_url! + url!
            setPreferences("pushUrl", nvalue: sub_url)
            setPreferences("isBackgroundPushClick", nvalue: "true")
            //print(">>> notification push url :  \(url)")
            if(getPreferences("isLuanch") == "1" ){
                //print(">>> notification isLuanch  == 1")
                setPreferences("isBackgroundPushClick", nvalue: "")
                
                /* 앱이 켜진 상태에서 PUSH 클릭 - 새로운 뷰를 호출한다 */
                if let rootViewController = window?.rootViewController as? UINavigationController {
                    if let viewController = rootViewController.viewControllers.first as? ViewController {
                        let murl = self.server_url! + self.main_url!
                        if(getPreferences("AUTO_LOGIN_TOKEN") != ""){
                            viewController.setUrl(sub_url as String?)
                        }else{
                            viewController.setUrl(murl as String?)
                        }
                    }
                }
            }else{
                print(">>> notification isLuanch  != 1")
            }
        }
        
        // Else handle any custom actions. . .
        completionHandler()
    }
    
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        debugPrint("handleEventsForBackgroundURLSession: \(identifier)")
        completionHandler()
    }
    
    /**
     * 서버에서 넘어온 값 파싱해서 url 값을 받아온다. String
     */
    private func parseRemoteNotification(notification:[String:AnyObject]) -> String? {
        if let identifier = notification["url"] as? String {
            return identifier
        }
        
        return nil
    }
}

// UserNoti를 앱 안에서 볼 수 있도록 extension 을 이용한다.
//Notification이 될때 해당 이벤트를 받아 completionHandler로 alert를 보낸다.
extension AppDelegate: UNUserNotificationCenterDelegate{
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert,.sound])
        
    }
    
    
}
