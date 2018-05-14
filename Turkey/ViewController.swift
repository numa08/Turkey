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

class ViewController: UIViewController,
TelloConnectedEventHandlerProtocol,
TelloVideoFrameEventHandlerProtocol,
ImageDecoderDelegate
{
    
    @IBOutlet weak var image: UIImageView!
    var videoData = NSMutableData()
    let imageDecoder = ImageDecoder()
    
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
    
    func decoder(_ decoder: ImageDecoder!, didDecode image: UIImage!) {
        DispatchQueue.main.async {
            self.image.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageDecoder.delegate = self
        if !self.imageDecoder.open() {
            fatalError("failed open fifo")
        }

//        let player = AVPlayer(url: URL(string: "udp://localhost:12345")!)
//        let vc = AVPlayerViewController()
//        vc.player = player
//        vc.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
//        self.addChildViewController(vc)
//        self.view.addSubview(vc.view)
//        player.play()
        
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

}

