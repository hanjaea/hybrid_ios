import Foundation
import UIKit


class CropImageController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    
    let imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        
        //            picker.allowsEditing = false
        //            picker.sourceType = .photoLibrary
        //            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        //            present(picker, animated: true, completion: nil)
        
        
        //            picker.allowsEditing = false
        //            picker.sourceType = UIImagePickerControllerSourceType.camera
        //            picker.cameraCaptureMode = .photo
        //            picker.modalPresentationStyle = .fullScreen
        //            present(picker,animated: true,completion: nil)
    }
}

