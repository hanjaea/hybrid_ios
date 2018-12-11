//
//  PopupView.swift
//  atxperbus
//
//  Created by Blue mobile on 2018. 3. 3..
//  Copyright © 2018년 atxpertbus. All rights reserved.
//

import Foundation

import WebKit
import UIKit
import Photos

class PopupView: UIViewController , WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    var appWebView:WKWebView?   //웹뷰
    var passUrl: String?        //메인에서 넘겨준 호출 URL
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //웹뷰 기본 세팅
        initWebView()
        
        //뷰컨트롤러에 웹뷰를 올린다
        view.addSubview(appWebView!)
        
        //웹뷰가 사용할 uiDelegate
        self.appWebView!.uiDelegate = self
        
        //웹뷰의 위치를 잡아주는 함수 호출
        setPosition()
        
        //상단 status bar 투명도 조절
        let statusView = UIView(frame: CGRect(x: 0, y: 0, width:     self.view.bounds.width, height: 20))
        statusView.backgroundColor = UIColor.white.withAlphaComponent(1)
        self.view.addSubview(statusView)
        
        //swipe gesture 막기
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        
        //임시 Start///////////////////////////////////////////////////////////////////////////////
        
        //임시 작성 3Line - 로컬 html 파일을 열기위해 작성되었으며 외부 URL 사용시 지워준다
        let htmlPath = Bundle.main.path(forResource: "detail", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
        appWebView!.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        
        //임시 주석 처리 - 외부 URL 사용시 풀어준다
        //setUrl(passUrl)
        
        //임시 End///////////////////////////////////////////////////////////////////////////////
        
    }
    
    /*
     메모리 관련 경고시 호출되는 기본 함수
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    
    }
    
    /*
     웹뷰 기본 세팅
     주요 기능
     - UserAgent에 커스텀 문자열 추가 (IosApp)
     - Javascript Interface를 위한 userContentController 추가 (IosApp)
     */
    func initWebView(){
        let webConfig:WKWebViewConfiguration = WKWebViewConfiguration()
        webConfig.userContentController.add(self, name: "IosApp")
        webConfig.websiteDataStore = WKWebsiteDataStore.default()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //webConfig.processPool = appDelegate.processPool as! WKProcessPool
        webConfig.processPool = appDelegate.processPool as! WKProcessPool
        
        appWebView = WKWebView(frame:CGRect.zero,configuration:webConfig)
        appWebView!.translatesAutoresizingMaskIntoConstraints = false
        appWebView!.allowsBackForwardNavigationGestures = true
        
        appWebView!.navigationDelegate = self
        
        let userAgent = UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent")! + " IosApp"
        UserDefaults.standard.register(defaults: ["UserAgent" : userAgent])
        appWebView!.customUserAgent = userAgent
    }
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
     웹뷰에 URL을 로드하는 함수
     */
    func setUrl(_ url:String!) {
        if url != nil {
            let url = URL(string:url)
            let request = URLRequest(url:url!)
            appWebView!.load(request)
        }
    }
    
    /*
     Javascript Bridge
     window.webkit.messageHandlers.pureApp.postMessage(JSONMessage)
     Javascript Interface에서 사용
     */
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let sentData = message.body as! NSDictionary
        let callname = sentData["callname"] as! String

        if (callname == "closePopup"){
            
            navigationController?.popToRootViewController(animated: false)
            dismiss(animated: false, completion: nil)
            
            
        }else if (callname == "setVariable"){
            setPreferences(sentData["key"] as! String, nvalue: sentData["value"] as! String)
        }else if(callname=="getVariable"){
            
            
            sendResponseString(getPreferences(sentData["key"] as! String), callback: sentData["callbackFunc"] as? String)
        }else if(callname=="callOutBrowser"){
            UIApplication.shared.openURL(URL(string: sentData["url"] as! String)!)
        }
        
    }
    
    
    /*
     Javascript로 String 리턴
     Javascript Interface에서 사용
     */
    func sendResponseString(_ aResponse:String?, callback:String?){
        guard let callbackString = callback else{
            return
        }
        
        appWebView!.evaluateJavaScript("(\(callbackString)('\(NSString(cString:aResponse!, encoding:String.Encoding.utf8.rawValue)!)'))"){(JSReturnValue:Any?, error:Error?) in
            if let errorDescription = error?.localizedDescription{
                print("returned value: \(errorDescription)")
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
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            print(url);
        }
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
}
