//
//  ViewController.swift
//  CropImg
//
//  Created by Duncan Champney on 3/24/15.
//  Copyright (c) 2015 Duncan Champney. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import WebKit
//-------------------------------------------------------------------------------------------------------


func loadShutterSoundPlayer() -> AVAudioPlayer?
{
    let theMainBundle = Bundle.main
    let filename = "Shutter sound"
    let fileType = "mp3"
    let soundfilePath: String? = theMainBundle.path(forResource: filename,
                                                    ofType: fileType,
                                                    inDirectory: nil)
    if soundfilePath == nil
    {
        return nil
    }
    //println("soundfilePath = \(soundfilePath)")
    let fileURL = URL(fileURLWithPath: soundfilePath!)
    var error: NSError?
    let result: AVAudioPlayer?
    do {
        result = try AVAudioPlayer(contentsOf: fileURL)
    } catch let error1 as NSError {
        error = error1
        result = nil
    }
    if let requiredErr = error
    {
        print("AVAudioPlayer.init failed with error \(requiredErr.debugDescription)")
    }
    if result?.settings != nil
    {
        //println("soundplayer.settings = \(settings)")
    }
    result?.prepareToPlay()
    return result
}

//-------------------------------------------------------------------------------------------------------

class CameraViewController:
    UIViewController,
    CroppableImageViewDelegateProtocol,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate, WKUIDelegate, WKNavigationDelegate
{
    
    @IBOutlet weak var whiteView: UIView!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var cropView: CroppableImageView!
    
    
    var base64sendFunc:String? = ""
    var beforeWebview:WKWebView?
    
    var shutterSoundPlayer = loadShutterSoundPlayer()
    
    override func viewDidAppear(_ animated: Bool) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status != .authorized {
            PHPhotoLibrary.requestAuthorization() {
                status in
            }
        }
    }
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum ImageSource: Int
    {
        case camera = 1
        case photoLibrary
    }
    
    func pickImageFromSource(
        _ theImageSource: ImageSource,
        fromButton: UIButton)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        switch theImageSource
        {
        case .camera:
            print("User chose take new pic button")
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.front;
        case .photoLibrary:
            print("User chose select pic button")
            imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        }
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            if theImageSource == ImageSource.camera
            {
                self.present(
                    imagePicker,
                    animated: true)
                {
                    //println("In image picker completion block")
                }
            }
            else
            {
                self.present(
                    imagePicker,
                    animated: true)
                {
                    //println("In image picker completion block")
                }
                
            }
        }
        else
        {
            self.present(
                imagePicker,
                animated: true)
            {
                print("In image picker completion block")
            }
            
        }
    }
    
    func saveImageToCameraRoll(_ image: UIImage) {

        
        var base64String:String? =  convertImageTobase64(format: .jpeg(0.5), image: image)
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if #available(iOS 10.0, *) {
            let objSomeViewController = storyBoard.instantiateViewController(withIdentifier:"main") as! ViewController
        } else {
            // Fallback on earlier versions
        }
        
        //objSomeViewController.imageString(base64:base64String,base64sendFunc:base64sendFunc);

        beforeWebview?.evaluateJavaScript("(\(base64sendFunc!))('data:image/jpeg;base64,\(base64String!)')", completionHandler: nil)
        
        
        
        navigationController?.popToRootViewController(animated: false)
        dismiss(animated: false, completion: nil)
        
    }
    public enum ImageFormat {
        case png
        case jpeg(CGFloat)
    }
    
    func convertImageTobase64(format: ImageFormat, image:UIImage) -> String? {
        var imageData: Data?
        switch format {
        case .png: imageData = UIImagePNGRepresentation(image)
        case .jpeg(let compression): imageData = UIImageJPEGRepresentation(image, compression)
        }
        
        return imageData?.base64EncodedString()
    }
    //-------------------------------------------------------------------------------------------------------
    // MARK: - IBAction methods -
    //-------------------------------------------------------------------------------------------------------
    
    @IBAction func handleSelectImgButton(_ sender: UIButton)
    {
        /*See if the current device has a camera. (I don't think any device that runs iOS 8 lacks a camera,
         But the simulator doesn't offer a camera, so this prevents the
         "Take a new picture" button from crashing the simulator.
         */
        let deviceHasCamera: Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        print("In \(#function)")
        
        //Create an alert controller that asks the user what type of image to choose.
        let anActionSheet =  UIAlertController(title: nil,
                                               message: nil,
                                               preferredStyle: UIAlertControllerStyle.actionSheet)
        
        
       
        //If the current device has a camera, add a "Take a New Picture" button
        var takePicAction: UIAlertAction? = nil
        if deviceHasCamera
        {
            takePicAction = UIAlertAction(
                title: "카메라",
                style: UIAlertActionStyle.default,
                handler:
                {
                    (alert: UIAlertAction)  in
                    self.pickImageFromSource(
                        ImageSource.camera,
                        fromButton: sender)
            }
            )
        }
        
        //Allow the user to selecxt an amage from their photo library
        let selectPicAction = UIAlertAction(
            title:"갤러리",
            style: UIAlertActionStyle.default,
            handler:
            {
                (alert: UIAlertAction)  in
                self.pickImageFromSource(
                    ImageSource.photoLibrary,
                    fromButton: sender)
        }
        )
        //return
        let returnAction = UIAlertAction(
            title:"돌아가기",
            style: UIAlertActionStyle.default,
            handler:
            {
                (alert: UIAlertAction)  in
                self.navigationController?.popToRootViewController(animated: false)
                self.dismiss(animated: false, completion: nil)
        }
        )
        
        let cancelAction = UIAlertAction(
            title:"Cancel",
            style: UIAlertActionStyle.cancel,
            handler:
            {
                (alert: UIAlertAction)  in
                print("User chose cancel button")
        }
        )
        
        if let requiredtakePicAction = takePicAction
        {
            anActionSheet.addAction(requiredtakePicAction)
        }
        anActionSheet.addAction(selectPicAction)
        anActionSheet.addAction(cancelAction)
        anActionSheet.addAction(returnAction)
        
        let popover = anActionSheet.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = sender.bounds;
        
        self.present(anActionSheet, animated: true)
        {
            //println("In action sheet completion block")
        }
    }
    
    
    @IBAction func handleCropButton(_ sender: UIButton)
    {
        //    var aFloat: Float
        //    aFloat = (sender.currentTitle! as NSString).floatValue
        //println("Button title = \(buttonTitle)")
        if let croppedImage = cropView.croppedImage()
        {
            self.whiteView.isHidden = false
            delay(0)
            {
                
                self.shutterSoundPlayer?.play()
                self.saveImageToCameraRoll(croppedImage)
                //UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
                
                delay(0.2)
                {
                    self.whiteView.isHidden = true
                    self.shutterSoundPlayer?.prepareToPlay()
                }
            }
            
            
            //The code below saves the cropped image to a file in the user's documents directory.
            /*------------------------
             let jpegData = UIImageJPEGRepresentation(croppedImage, 0.9)
             let documentsPath:String = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
             NSSearchPathDomainMask.UserDomainMask,
             true).last as String
             let filename = "croppedImage.jpg"
             var filePath = documentsPath.stringByAppendingPathComponent(filename)
             if (jpegData.writeToFile(filePath, atomically: true))
             {
             println("Saved image to path \(filePath)")
             }
             else
             {
             println("Error saving file")
             }
             */
        }
    }
    
    //-------------------------------------------------------------------------------------------------------
    // MARK: - CroppableImageViewDelegateProtocol methods -
    //-------------------------------------------------------------------------------------------------------
    
    func haveValidCropRect(_ haveValidCropRect:Bool)
    {
        //println("In haveValidCropRect. Value = \(haveValidCropRect)")
        cropButton.isEnabled = haveValidCropRect
    }
    //-------------------------------------------------------------------------------------------------------
    // MARK: - UIImagePickerControllerDelegate methods -
    //-------------------------------------------------------------------------------------------------------
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : Any])
    {
        print("In \(#function)")
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            picker.dismiss(animated: true, completion: nil)
            cropView.imageToCrop = image
            cropView.setNeedsDisplay()
        }
        //cropView.setNeedsLayout()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        print("In \(#function)")
        picker.dismiss(animated: true, completion: nil)
    }
}

