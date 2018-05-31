//
//  ViewController.swift
//  Turkey
//
//  Created by numa08 on 2018/05/08.
//  Copyright © 2018年 numa08. All rights reserved.
//

import UIKit
import Tello
import AVFoundation
import AVKit
import Vision

class ViewController: UIViewController,
TelloConnectedEventHandlerProtocol,
TelloVideoFrameEventHandlerProtocol,
ImageDecoderDelegate
{
    
    @IBOutlet weak var image: UIImageView!
    var videoData = NSMutableData()
    let imageDecoder = ImageDecoder()
    lazy var highlightView: UIView = {
        let v = UIView()
        v.layer.borderColor = UIColor.blue.cgColor
        v.layer.borderWidth = 4
        v.layer.backgroundColor = UIColor.clear.cgColor
        return v
    }()
    private var requestHandler: VNSequenceRequestHandler = VNSequenceRequestHandler()
    private var lastObservation: VNDetectedObjectObservation?
    private var isTouched: Bool = false
    private let objectDetectionQueue = DispatchQueue(label: "object-detection")
    func conected() {
        print("Connected")
        TelloStartVideo(nil)
        TelloSetVideoEncoderRate(4, nil)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (_) in
            TelloStartVideo(nil)
        }
    }
    
    func videoFrame(_ p0: Data!) {
        self.imageDecoder.onNewFrame(p0)
    }

    private func drawFaceRectangle(image: UIImage?, observation: VNFaceObservation) -> UIImage? {
        let imageSize = image!.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        image?.draw(in: CGRect(origin: .zero, size: imageSize))
        context?.setLineWidth(4.0)
        context?.setStrokeColor(UIColor.green.cgColor)
        context?.stroke(observation.boundingBox.converted(to: imageSize))
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return drawnImage
    }
    
    
    func decoder(_ decoder: ImageDecoder!, didDecode image: UIImage!) {
        DispatchQueue.main.async {
            self.image.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.image.addSubview(self.highlightView)
        imageDecoder.delegate = self
        if !self.imageDecoder.open() {
            fatalError("failed open fifo")
        }
        DispatchQueue(label: "tello").async {
            TelloInitDrone("8090")
            TelloRegisterOnConnectedEvent(self, nil)
            TelloRegisterVideoFrameEvent(self, nil)
            TelloStart(nil)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func convertedRect(rect: CGRect, to size: CGSize) -> CGRect {
        // view 上の長方形に変換する
        // 座標系変換のため、 Y 軸方向に反転する
        return CGRect(x: rect.minX * size.width, y: (1.0 - rect.maxY) * size.height, width: rect.width * size.width, height: rect.height * size.height)
    }
}

extension CGRect {
    func converted(to size: CGSize) -> CGRect {
        return CGRect(x: self.minX * size.width, y: (1 - self.maxY) + size.height, width: self.width * size.width, height: self.height * size.height)
    }
}
