//
//  ViewController.swift
//  Bird
//
//  Created by Chang Yu on 9/5/19.
//  Copyright © 2019 Chang Yu. All rights reserved.
//
//这个版本是服务器好用的！！！！！
import UIKit
import CoreML
import Alamofire

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classifier: UILabel!
    
    @IBOutlet weak var Probability: UILabel!
    
//    var timer = Timer()
    
    
    
    
    
//    func preprocess(image: UIImage, width: Int, height: Int) -> MLMultiArray? {
//        let size = CGSize(width: width, height: height)
//
//
//        guard let pixels = image.resize(to: size).pixelData()?.map({ (Double($0) / 255.0) }) else {
//            return nil
//        }
//
//        guard let array = try? MLMultiArray(shape: [3, height, width] as [NSNumber], dataType: .double) else {
//            return nil
//        }
//
//        let r = pixels.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
//        let g = pixels.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
//        let b = pixels.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }
//
//        let combination = r + g + b
//        for (index, element) in combination.enumerated() {
//            array[index] = NSNumber(value: element)
//        }
//
//        return array
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        Alamofire.request("http://34.73.178.43:5000/up_photo").responseJSON { (response) in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")
//
//
//            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8){
//                print("Data: \(utf8Text)")
//            }
//        }
        
    }
    
    
//    override func viewWillAppear(_ animated: Bool) {
//        model = Inceptionv3()
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func camera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    

}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true)
        classifier.text = "Analyzing Image..."
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        } //1
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
//        var imageup = UIImage(named: "photo")
        
//        imageup = newImage
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imageView.image = newImage
        
//        let uploadImage = UIImage(named: "photo")
        
        
        //上传方法
        let imageData = UIImagePNGRepresentation(newImage)!
//        Alamofire.upload(imageData, to: "http://34.73.178.43:5000/up_photo").responseJSON { (response) in
//            debugPrint(response)
//        }

        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imageData, withName: "photo", fileName: "photo.png", mimeType: "photo/png")
        }, to: "http://35.244.82.225:5000/up_photo") { (result) in
            
            switch result{
                
                
            case .success(let upload , _, _):
                
//                upload.responseJSON(completionHandler: { (responsejson) in
//                    if let json = responsejson.result.value{
//                        print("收到的是\(json)")
//                    }
//                })
                
                upload.responseString{ response in
                    debugPrint(response)
                }
//
                .uploadProgress { progress in

                        print("Upload Progress \(progress.fractionCompleted)")

                }
                
                    .responseJSON { responsejson in
                        if let json = responsejson.result.value{
                            print("Received json is\(json)")
                            let bird : AnyObject = (json as AnyObject).object(forKey: "birds") as AnyObject
                            let probability : AnyObject = (json as AnyObject).object(forKey: "probability") as AnyObject
                            self.classifier.text = "This is a \(bird)\nThe probability of \(bird) is \(probability)"
//                            self.Probability.text = "The probability of \(bird) is \(probability)"
//
                    }
                }

                
//            Alamofire.request("http://127.0.0.1/test.json").responseJSON(completionHandler: { (response) in
//                if let json = response.result.value{
//                    print("收到的json是\(json)")
//                }
//            })
                
                
                
                return
            case .failure(let encodingError):
                debugPrint(encodingError)
            }
        }
        
//        Alamofire.request("http://127.0.0.1").responseJSON { (response) in
//
//            if let json = response.result.value{
//                print("返回的Json是\(json)")
//            }
//        }
        
        
        // Core ML
//        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
//            return
//        }
//        
//        classifier.text = "I think this is a \(prediction.classLabel)."
        
        
    }
    
//上传
//    func uploadImage(imageData : Data){
//        Alamofire.upload(
//            multipartFormData: { multipartFormData in
//                //采用post表单上传
//                // 参数解释：
//                //withName:和后台服务器的name要一致 ；fileName:可以充分利用写成用户的id，但是格式要写对； mimeType：规定的，要上传其他格式可以自行百度查一下
//                multipartFormData.append(imageData, withName: "photo", fileName: "123456.jpg", mimeType: "image/jpeg")
//                //如果需要上传多个文件,就多添加几个
//                //multipartFormData.append(imageData, withName: "file", fileName: "123456.jpg", mimeType: "image/jpeg")
//                //......
//
//
//        },to: uploadURL,encodingCompletion: { encodingResult in
//            switch encodingResult {
//            case .success(let upload, _, _):
//                //连接服务器成功后，对json的处理
//                upload.responseJSON { response in
//                    //解包
//                    guard let result = response.result.value else { return }
//                    print("json:\(result)")
//                }
//                //获取上传进度
//                upload.uploadProgress(queue: DispatchQueue.global(qos: .utility)) { progress in
//                    print("图片上传进度: \(progress.fractionCompleted)")
//                }
//            case .failure(let encodingError):
//                //打印连接失败原因
//                print(encodingError)
//            }
//        })
//    }
    

}
