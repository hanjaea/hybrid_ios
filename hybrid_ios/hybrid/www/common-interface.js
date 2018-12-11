/**
 *
 *    Javascript, Native(iOS,Android)간 Interface 공통
 *    작성자 : YT
 *    작성일 : 2018.07.04
 *
 *
 *    1. Native User Agent
 *        Android    :    AppDroid
 *        IOS        :    IosApp
 *
 *    2. Call Native
 *        Android :     window.AppDroid.~
 *        IOS        :     window.webkit.messageHandlers.IosApp.postMessage(~);
 */
var hUserAgent = navigator.userAgent;

var interface = {
    /**
     *    네이티브 값 가져오기
     */
getVariable: function (key,func){
    
    var message = {
        "callname":"getVariable",
        "key":key,
        "callbackFunc":func.toString()
    };
    
    if(hUserAgent.indexOf("AppDroid") != -1){
        
        var value = window.AppDroid.getVariable(key);
        
        func(value);
        
        
    }else if(hUserAgent.indexOf("IosApp") != -1){
        window.webkit.messageHandlers.IosApp.postMessage(message);
    }
    
}
    
    /**
     *    네이티브 값 저장하기
     */
    ,setVariable: function (key,value){
        
        var message = {
            "callname":"setVariable",
            "key":key,
            "value":value
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            window.AppDroid.setVariable(key,value);
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
        
    }
    /**
     *    앱 버전 가져오기
     */
    ,getAppVersion: function (func){
        this.getVariable("dVersion",func);
    }
    /**
     *   모델정보 가져오기
     */
    ,getAppModel: function (func){
        this.getVariable("dModel",func);
    }
    /**
     *    토큰ID 가져오기
     */
    ,getTokenId: function (func){
        this.getVariable("tokenId",func);
    }
    /**
     *   외부 브라우저 호출
     */
    ,callOutBrowser: function(url){
        var message = {
            "callname":"callOutBrowser",
            "url":url
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            window.AppDroid.callOutBrowser(url);
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
    }
    /**
     *  새로운 뷰를 호출
     */
    ,callAnotherView: function(url){
        var message = {
            "callname":"callAnotherView",
            "url":url
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            window.AppDroid.callAnotherView(url);
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
    }
    /**
     *  팝업 닫기 호출 (새로운 뷰에서 사용)
     */
    ,closePopup: function(){
        var message = {
            "callname":"closePopup"
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            window.AppDroid.closePopup();
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
    }
    /**
     *   카메라 호출
     */
    ,getCamera: function(func){
        var message = {
            "callname":"getCamera",
            "callbackFunc":((func.toString()).replace(/\n/g,'')).replace(/ /g,'')
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            window.AppDroid.getCamera(((func.toString()).replace(/\n/g,'')).replace(/ /g,''));
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
    }
    
    /**
     * URL을 통한 동영상 다운로드
     */
    ,fileDownload: function(url,ext,func){
        alert('fileDownload : ' + url);
        var message = {
            "callname":"fileDownload",
            "url":url,
            "ext":ext,
            "callbackFunc":func.toString()
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            var value = window.AppDroid.fileDownload(url);
            
            func(value);
            
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
        
    }
    /**
     * URL을 통한 동영상 다운로드
     */
    ,fileDownload: function(url,ext, func){
        alert('fileDownload : ' + url);
        var message = {
            "callname":"fileDownload",
            "url":url,
            "ext":ext
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            var value = window.AppDroid.fileDownload(url);
            func(value);
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }
        
    }
    /**
     * URL을 통한 동영상 다운로드
     */
    ,downloadVideo: function(url,func){
        
        var message = {
            "callname":"downloadVideo",
            "url":url,
            "callbackFunc":func.toString()
        };
        
        if(hUserAgent.indexOf("AppDroid") != -1){
            
            var value = window.AppDroid.downloadVideo(url);
            
            //func(value);
            
            
        }else if(hUserAgent.indexOf("IosApp") != -1){
            window.webkit.messageHandlers.IosApp.postMessage(message);
        }

    }
    
    
};
