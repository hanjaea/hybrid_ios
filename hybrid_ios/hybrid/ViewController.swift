//
//  ViewController.swift
//  Created by jahan on 2018. 10. 3..
//  Copyright © 2018년 gmkApp. All rights reserved.
//
import Foundation
import UIKit
import WebKit
import UserNotifications
import Photos
import AssetsLibrary

@available(iOS 10.0, *)
class ViewController: UIViewController, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let webViewContanner = UIView()
    var appWebView:WKWebView?   //웹뷰

    var progressBar : UIProgressView!
    var sentData:NSDictionary? = nil
    var sub_url:String? = ""   //호출 URL (루트 URL + 서브 URL)
    var imageView: UIImageView? //웹뷰의 로딩이 끝날때까지 띄워줄 이미지 뷰
    var isLoadFirst = true  //첫번째 로드인지 확인하는 변수
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // 현재 forground 상태임을 설정
        setPreferences("isLuanch", nvalue: "1")
        /*
         가장 먼저 탈옥 여부를 체크 후
         루트 권한을 가진 디바이스라면 알림을 띄운 후 앱을 종료한다
         */
        if(hasJailbreak()){
            //얼럿다이얼로그 생성
            let dialog = UIAlertController(title: nil, message: "루트권한을 가진 디바이스에서는 실행할 수 없습니다.", preferredStyle: .alert)
            //확인 버튼 클릭 시 앱 종료
            let action = UIAlertAction(title: "확인", style: UIAlertActionStyle.default){
                (action:UIAlertAction!) in
                exit(0)
            }
            dialog.addAction(action)
            self.present(dialog, animated: true, completion: nil)
        }
        
        //실제로 처음에 호출될 URL을 조합한다
        if(getPreferences("AUTO_LOGIN_TOKEN") != ""){
            sub_url = appDelegate.server_url! + appDelegate.main_url!
        }else{
            sub_url = appDelegate.server_url! + appDelegate.login_url!
        }
        
        //웹뷰 기본 세팅
        initWebView()
        
        //서버와 버전체크 호출
        versionCheck();
        
        let token = getPreferences("tokenId")
        print(">>> ViewController token : \(token)")
        
        //디바이스 버전정보를 Preference에 저장
        setPreferences("dVersion",nvalue:  Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
        //디바이스 모델정보를 Preference에 저장
        setPreferences("dModel",nvalue:  UIDevice.current.model)
        
        //뷰컨트롤러에 웹뷰를 올린다
        view.addSubview(appWebView!)
        
        //웹뷰의 위치를 잡아주는 함수 호출
        setPosition()
    
        //swipe gesture 막기
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false

    }
    
    override func viewWillAppear(_ animated: Bool) {
        //UIApplication.shared.isNetworkActivityIndicatorVisible = false
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    /*
     웹뷰에서 로드가 완료되었을 때 호출되는 함수
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        //최초 로드 시
        if(isLoadFirst){
            isLoadFirst = !isLoadFirst
            //상단 status bar 투명도 조절
            let statusView = UIView(frame: CGRect(x: 0, y: 0, width:     self.view.bounds.width, height: 20))
            statusView.backgroundColor = UIColor.white.withAlphaComponent(1)
            self.view.addSubview(statusView)
        }
    }
    
    /*
     탈옥된 기기인지 체크하는 함수
     - 시뮬레이터 체크
     - 시디아 패키지 접근 url이 접속 가능한지 체크
     - 탈옥 관련 앱이 설치 되어있는지 체크
     - 루트권한이 있어야 접근 가능한 경로에 접근 가능한지 체크
     */
    func hasJailbreak() -> Bool {
        
        //시디아 패키지 접근 url이 접속 가능한지 체크
        guard let cydiaUrlScheme = NSURL(string: "cydia://package/com.example.package") else { return false }
        if UIApplication.shared.canOpenURL(cydiaUrlScheme as URL) {
            return true
        }
        //시뮬레이터 체크
        #if arch(i386) || arch(x86_64)
        // This is a Simulator not an idevice
        return false
        #endif
        
        //탈옥 관련 앱이 설치 되어있는지 체크
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: "/Applications/Cydia.app") ||
            fileManager.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            fileManager.fileExists(atPath: "/bin/bash") ||
            fileManager.fileExists(atPath: "/usr/sbin/sshd") ||
            fileManager.fileExists(atPath: "/etc/apt") ||
            fileManager.fileExists(atPath: "/usr/bin/ssh") ||
            fileManager.fileExists(atPath: "/private/var/lib/apt") {
            return true
        }
        //루트권한이 있어야 접근 가능한 경로에 접근 가능한지 체크
        if canOpen(path: "/Applications/Cydia.app") ||
            canOpen(path: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            canOpen(path: "/bin/bash") ||
            canOpen(path: "/usr/sbin/sshd") ||
            canOpen(path: "/etc/apt") ||
            canOpen(path: "/usr/bin/ssh") {
            return true
        }
        let path = "/private/" + NSUUID().uuidString
        do {
            try "anyString".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    /*
     해당 경로에 접근이 가능한지 여부를 체크하는 함수
     */
    func canOpen(path: String) -> Bool {
        let file = fopen(path, "r")
        guard file != nil else { return false }
        fclose(file)
        return true
    }
    /*
     화면이 완전히 나타났을 때 호출되는 기본 함수
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setStatusBarBackgroundColor()
        
    }
    /*
     메모리 관련 경고시 호출되는 기본 함수
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setStatusBarBackgroundColor() {
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = UIColor.white
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    /*
     웹뷰 기본 세팅
     주요 기능
     - UserAgent에 커스텀 문자열 추가 (IosApp)
     - Javascript Interface를 위한 userContentController 추가 (IosApp)
     */
    func initWebView(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.processPool = WKProcessPool()
        
        let webConfig:WKWebViewConfiguration = WKWebViewConfiguration()
        webConfig.userContentController.add(self, name: "IosApp")
        webConfig.websiteDataStore = WKWebsiteDataStore.default()
        webConfig.processPool = appDelegate.processPool as! WKProcessPool
        webConfig.ignoresViewportScaleLimits = true
        
        appWebView = WKWebView(frame:CGRect.zero,configuration:webConfig)
        appWebView!.translatesAutoresizingMaskIntoConstraints = false
        appWebView!.allowsBackForwardNavigationGestures = true
        appWebView!.uiDelegate = self
        appWebView!.navigationDelegate = self
        
        //appWebView!.translatesAutoresizingMaskIntoConstraints = true

        //appWebView!.scrollView.delegate = self
        //appWebView!.scrollView.delegate = (self as! UIScrollViewDelegate)
        
        let userAgent = UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent")! + "  IosApp"
        UserDefaults.standard.register(defaults: ["UserAgent" : userAgent])
        appWebView!.customUserAgent = userAgent
        
    }
    
    //MARK: - UIScrollViewDelegate
    //func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    //    scrollView.pinchGestureRecognizer?.isEnabled = false
    //}
    
    /*
     웹뷰의 위치를 잡아주는 함수
     */
    func setPosition() {
        appWebView!.translatesAutoresizingMaskIntoConstraints = false;
        let height = NSLayoutConstraint(item: appWebView!, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: appWebView!, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item:appWebView!,attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        view.addConstraints([height, width, top])
    }
    /*
     WKWebView에 URL을 로드한다 (푸시, 자동로그인 등에 필요한 각 헤더값을 세팅해준다)
     */
    func setUrl(_ url:String!) {
        if url != nil {
            let url = URL(string:url)!
            var request = URLRequest(url:url)
            let token:String? = "7a6ad103f7aad2a91d7f2859d835462ca3c994800cd65850c83361eee7f3ab1e".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            //let token:String? = (getPreferences("tokenId")).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let model = UIDevice.current.model;
            let mobIdtfChar:String? = (getPreferences("AUTO_LOGIN_TOKEN")).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            //헤더 값 세팅
            request.addValue(token!, forHTTPHeaderField: "TOKEN")
            request.addValue(Bundle.main.infoDictionary?["CFBundleVersion"] as! String, forHTTPHeaderField: "MOB_TRMNL_OS_VER");
            request.addValue(model, forHTTPHeaderField: "MOB_TRMNL_MODEL_NAME");
            request.addValue(mobIdtfChar!, forHTTPHeaderField: "MOB_IDTF_CHAR");
            request.addValue(mobIdtfChar!, forHTTPHeaderField: "AUTO_LOGIN_TOKEN");
            request.addValue("iOS", forHTTPHeaderField: "MOB_TRMNL_OS_TYPE");
            //임시 Start///////////////////////////////////////////////////////////////////////////////
            //임시 작성 3Line - 로컬 html 파일을 열기위해 작성되었으며 외부 URL 사용시 지워준다
            let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
            let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
            appWebView!.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
             //임시 End///////////////////////////////////////////////////////////////////////////////
            
            //임시 주석 처리 - 외부 URL 사용시 풀어준다
            //print("setUrl ~~~ \(request.description as String?)")
            //appWebView!.load(request)
        }
    }
    
    /*
     Javascript Bridge
     window.webkit.messageHandlers.IosApp.postMessage(JSONMessage)
     Javascript Interface에서 사용
     */
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        //let sentData = message.body as! NSDictionary
        sentData = (message.body as! NSDictionary)
        
        let callname = sentData!["callname"] as! String
        
        if (callname == "setVariable"){
            setPreferences((sentData!["key"] as! String), nvalue: (sentData!["value"] as! String))
        }else if(callname=="getVariable"){
            sendResponseString(getPreferences((sentData!["key"] as! String)), callback: sentData!["callbackFunc"] as? String)
        }else if(callname=="callOutBrowser"){
            //UIApplication.shared.openURL(URL(string: sentData["url"] as! String)!)
            guard let url = URL(string: sentData!["url"] as! String) else { return }
            UIApplication.shared.openURL(url)
        }else if(callname=="getCamera"){
            /*
            let storyBoard : UIStoryboard = UIStoryboard(name: "Camera", bundle:nil)
            let objSomeViewController = storyBoard.instantiateViewController(withIdentifier:"camera") as! CameraViewController
            
            let base64sendFunc = sentData!["callbackFunc"] as! String
            objSomeViewController.base64sendFunc = base64sendFunc
            objSomeViewController.beforeWebview = appWebView
            
            self.navigationController?.pushViewController(objSomeViewController, animated: false)
            
             
             let storyBoard : UIStoryboard = UIStoryboard(name: "Camera", bundle:nil)
             let objSomeViewController = storyBoard.instantiateViewController(withIdentifier:"camera") as! CameraViewController
             
             let base64sendFunc = sentData["callbackFunc"] as! String
             objSomeViewController.base64sendFunc = base64sendFunc
             objSomeViewController.beforeWebview = appWebView
             
             self.navigationController?.pushViewController(objSomeViewController, animated: false)
             */
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Camera", bundle:nil)
            let objSomeViewController = storyBoard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
            
            let base64sendFunc = sentData!["callbackFunc"] as! String
            objSomeViewController.base64sendFunc = base64sendFunc
            objSomeViewController.beforeWebview = appWebView
            
            self.navigationController?.pushViewController(objSomeViewController, animated:false)
    
        }else if(callname=="fileDownload"){
            showToast(message: "다운로드를 시작합니다")
            let ext = sentData!["ext"] as! String
            let videoImageUrl = sentData!["url"] as! String
            if URL(string: "\(videoImageUrl)") != nil {
                DispatchQueue.main.async{
                    let fileManager = FileManager.default
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

                    let dataPath = documentsDirectory.appendingPathComponent("Files", isDirectory: true)
                    let url1 = URL(string: videoImageUrl)
                    let destination = dataPath.appendingPathComponent("\(Int64(Date().timeIntervalSince1970))_.\(ext)")
                    
                    let filePath =  documentsDirectory.appendingPathComponent("Files")
                    if !fileManager.fileExists(atPath: filePath.path) {
                        do {
                            try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            NSLog("Couldn't create document directory")
                        }
                    }
                    self.load(url: url1!, to: destination)  // front로 아무것도 던져주지 않는다.
                }
            }
        }
    }
    
    func load(url: URL, to localUrl: URL){
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
                        self.showAlert(str: "다운로드 완료")
                    }
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                } catch (let writeError){
                    print("error writing file \(localUrl) : \(writeError)")
                    DispatchQueue.main.async {
                        //appDelegate.sendNotification(title: "파일 저장시 발생했습니다")
                        self.showAlert(str: "파일 저장시 오류가 발생했습니다")
                    }
                }
            }else {
                print("Failure: %@", error?.localizedDescription as Any);
                DispatchQueue.main.async {
                    self.showAlert(str: "다운로드시 장애가 발생했습니다")
                    //if istrue == "true"{
                    //    self.sendResponseString("다운로드시 장애가 발생했습니다", callback: "callbackFunc")
                    //}
                }
            }
            
        }
        task.resume()
    }
    
    /**
     * 서버와 버전 체크
     */
    func versionCheck(){
        
        let url = URL(string: "\(appDelegate.version_url!)?osTypeCd=IOS")
        URLSession.shared.dataTask(with: url!, completionHandler: {
            (data, response, error) in
            if(error != nil){
                print("error")
            }else{
                
                var isDialog: Bool = false
                
                 // 실제 json 으로 리턴 받았을 때 사용
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : Any]
                    let respData = json["data"] as? [String:Any]
                    let serverVerStr = respData!["appVersion"] as? String
                    let serverWords = serverVerStr?.components(separatedBy:".")
                    let serverStr1 = serverWords![0] as String
                    let serverStr2 = serverWords![1] as String
                    let serverStr3 = serverWords![2] as String
                    
                    let serverInt1: Int = Int(serverStr1)! * 10000
                    let serverInt2: Int = Int(serverStr2)! * 100
                    let serverInt3: Int = Int(serverStr3)! * 1
                    
                    let serverVerNum: Int = serverInt1 + serverInt2 + serverInt3
                    
                    let localVerStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                    
                    let localWords = localVerStr?.components(separatedBy:".")
                    let localStr1 = localWords![0] as String
                    let localStr2 = localWords![1] as String
                    let localStr3 = localWords![2] as String
                    
                    let localInt1: Int = Int(localStr1)! * 10000
                    let localInt2: Int = Int(localStr2)! * 100
                    let localInt3: Int = Int(localStr3)! * 1
                    
                    let localVerNum: Int = localInt1 + localInt2 + localInt3
                    
                    if(serverVerNum > localVerNum ){
                        isDialog = true
                        let dialog = UIAlertController(title: nil, message: "새로운 앱이 존재합니다. \n마켓으로 이동합니다.", preferredStyle: .alert)
                        let action = UIAlertAction(title: "확인", style: UIAlertActionStyle.default){
                            (action:UIAlertAction!) in
                            // 향후 해당 앱 아이디로 수정해야 함
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id282935706"),
                                UIApplication.shared.canOpenURL(url)
                            {
                                if #available(iOS 10.0, *) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                } else {
                                    UIApplication.shared.openURL(url)
                                }
                                sleep(1)
                                exit(0)
                            }
                        }
                        dialog.addAction(action)
                        self.present(dialog, animated: true, completion: nil)
                    }
                }catch let error as NSError{
                    print(error)
                }
 
                self.setUrl(self.sub_url);

            }
        }).resume()

    }
    
    
    /*
     패 Javascript로 String 리턴
     Javascript Interface에서 사용
     */
    func sendResponseString(_ aResponse:String?, callback:String?){
        guard let callbackString = callback else{
            return
        }
        
        appWebView!.evaluateJavaScript("(\(callbackString)('\(NSString(cString:aResponse!, encoding:String.Encoding.utf8.rawValue)!)'))"){(JSReturnValue:Any?, error:Error?) in
            if let errorDscription = error?.localizedDescription {
                print("returned value: \(errorDscription)")
            }
            else if JSReturnValue != nil{
                print("returned value: \(JSReturnValue!)")
            }
        }
    }
    /*
     Javascript로 Object 리턴
     Javascript Interface에서 사용
     */
    func sendResponseObject(_ aResponse:Dictionary<String,AnyObject>, callback:String?){
        guard let callbackString = callback else{
            return
        }
        guard let generatedJSONData = try? JSONSerialization.data(withJSONObject: aResponse, options: JSONSerialization.WritingOptions(rawValue: 0)) else{
            print("failed to generate JSON for \(aResponse)")
            return
        }
        appWebView!.evaluateJavaScript("(\(callbackString)('\(NSString(data:generatedJSONData, encoding:String.Encoding.utf8.rawValue)!)'))"){(JSReturnValue:Any?, error:Error?) in
            if let errorDescription = error?.localizedDescription{
                print("returned value: \(errorDescription)")
            }
            else if JSReturnValue != nil{
                print("returned value: \(JSReturnValue!)")
            }
        }
    }
    
    /*
     얼럿 다이얼로그
     해당 함수를 작성하지 않으면 다이얼로그창이 뜨지않음
     */
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler()
        }
        alertController.addAction(otherAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /*
     컨펌 다이얼로그
     해당 함수를 작성하지 않으면 다이얼로그창이 뜨지않음
     */
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    /*
     프롬프트 다이얼로그
     해당 함수를 작성하지 않으면 다이얼로그창이 뜨지않음
     */
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        // variable to keep a reference to UIAlertController
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        
        let okHandler: () -> Void = {
            if let textField = alertController.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler("")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in completionHandler("")
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            action in okHandler()
        }
        alertController.addTextField() { $0.text = defaultText }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    /*
     네이티브 값 저장
     setPreferences("key",nvalue:"value")
     */
    func setPreferences(_ nkey:String!,nvalue:String!){
        print("nkey :\(String(describing: nkey)) | nvalue : \(String(describing: nvalue))")
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
    /*
     네이티브 저장 값 삭제
     removePreferences("key")
     */
    func removePreferences(_ nkey:String!){
        UserDefaults.standard.set("", forKey: nkey)
    }
    /*
     URL이 변경되고 호출되기 전에 발생되는 이벤트 (tel, mailto 등의 이벤트를 처리)
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let url = navigationAction.request.url!
        
        if "\(url)".starts(with: "tel:") {
            
            decisionHandler(.cancel)
            
            if let telUrl = URL(string: "\(url)".replacingOccurrences(of: "tel:", with: "tel://", options: .literal, range: nil)), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(telUrl)
                } else {
                    UIApplication.shared.openURL(telUrl)
                }
            }
        } else{
            decisionHandler(.allow)
            
            
        }
    }
    /*
     SSL 인증서가 올바르지 않은 페이지도 로드할 수 있게 해주는 WKWebView 기본 함수
     */
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    /*
     Alert Dialog 생성
     */
    func showAlert(str:String){
        //얼럿다이얼로그 생성
        let dialog = UIAlertController(title: nil, message: str, preferredStyle: .alert)
        //확인 버튼 클릭 시 앱 종료
        let action = UIAlertAction(title: "확인", style: UIAlertActionStyle.default){
            (action:UIAlertAction!) in
        }
        dialog.addAction(action)
        self.present(dialog, animated: true, completion: nil)
    }
    
    
}
/**
 * Toast 알림 창 띄우기
 */
extension UIViewController {
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width:180, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay:0.1 , options: .curveEaseOut, animations : {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
        
        
        
    }
}
extension UIView {
    
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.topAnchor
        } else {
            return self.topAnchor
        }
    }
    
    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *){
            return self.safeAreaLayoutGuide.leftAnchor
        }else {
            return self.leftAnchor
        }
    }
    
    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *){
            return self.safeAreaLayoutGuide.rightAnchor
        }else {
            return self.rightAnchor
        }
    }
    
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.bottomAnchor
        } else {
            return self.bottomAnchor
        }
    }
}
extension String {
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}
