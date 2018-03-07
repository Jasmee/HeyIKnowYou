//
//  ViewController.swift
//  HeyIKnowYou
//
//  Created by Jasmee Sengupta on 07/03/18.
//  Copyright © 2018 Jasmee Sengupta. All rights reserved.
//  **Do not commit model inceptionv3, 94.7 MB not to be pushed to github**

import UIKit
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //why is navdel needed?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classifierLabel: UILabel!
    var model: Inceptionv3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        model = Inceptionv3()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCamera(_ sender: UIBarButtonItem) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("Camera not available")
            return
        }
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self// declare 2 dlegates for assigning
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        present(cameraPicker, animated: true, completion: nil)
    }
    
    @IBAction func openPhotoLibrary(_ sender: UIBarButtonItem) {
        let photoPicker = UIImagePickerController()
        photoPicker.delegate = self
        photoPicker.sourceType = .photoLibrary
        photoPicker.allowsEditing = false
        present(photoPicker, animated: true, completion: nil)
    }
    
    // MARK: Model method
    
    // MARK: ImagepickerController delegates
    
    //    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    //        dismiss(animated: true, completion: nil)
    //    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        classifierLabel.text = "Analyzing image..."
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            print("Could not pick the image")
            return
        }
        guard let newImage = convertImage(image: image)  else {
            print("Could not rescale image")
            return
        }
        imageView.image = newImage
    }
    
    // MARK: Image editing
    
    func size(image: UIImage, width: Int, height: Int) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func convertImage(image: UIImage) -> UIImage? {
        let newImage = size(image: image, width: 299, height: 299)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
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
        predictTypeOf(image: pixelBuffer!)
        return newImage
    }
    
    func predictTypeOf(image: CVPixelBuffer) {
        
        guard let prediction = try? model?.prediction(image: image) else {
            print("No predictions for this image")
            return
        }
        guard let possibility = prediction?.classLabel else {
            return
        }
        classifierLabel.text = "I think you are a \(possibility)"
        print(possibility)
        
        if let probabilities = prediction?.classLabelProbs { // [String: Double]
            print(probabilities.count) //999 for inceptionv3
            if let probability = probabilities[possibility] {
                classifierLabel.text = classifierLabel.text! + " with a \(probability * 100)% certainty"
                print("with a \(probability * 100)% certainty")
            }
        }
//        if let features = prediction?.featureNames {
//            print(features) // ["classLabel", "classLabelProbs"]
//        }
    }
    
}
