//
//  FaceTracker.swift
//  Turkey
//
//  Created by numa08 on 2018/06/19.
//  Copyright © 2018年 numa08. All rights reserved.
//

import Foundation
import Vision


protocol FaceTrackerDelegate {
    func handleFacePosition(positions: [VNDetectedObjectObservation])
    func error(error: Error)
}
class FaceTracker {
    
    enum FacetrackingError: Error {
        case getCgImageError
        case getImageOrientationError
    }

    var delegate: FaceTrackerDelegate? = nil

    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    private let visionFrameworkTaskQueue = DispatchQueue(label: "vision")

    init() {
        self.prepareVisionRequest()
    }
    
    fileprivate func prepareVisionRequest() {
        var requests = [VNTrackObjectRequest]()
        let faceDetetionRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let error = error {
                print("FaceDetection error: \(String(describing: error))")
            }
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            DispatchQueue.main.async {
                for observation in results {
                    let faceTrackingRequest =  VNTrackObjectRequest(detectedObjectObservation: observation, completionHandler: {(request, error) in
                        if let error = error {
                            print("FaceTracking error: \(String(describing: error))")
                        }
                        guard let trackingRequest = request as? VNTrackObjectRequest,
                            let results = trackingRequest.results as? [VNDetectedObjectObservation] else {
                                return
                        }
                        DispatchQueue.main.async {
                            self.delegate?.handleFacePosition(positions: results)
                        }
                    })
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        }
        self.detectionRequests = [faceDetetionRequest]
        self.sequenceRequestHandler = VNSequenceRequestHandler()
    }
    
    func trackFace(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            self.delegate?.error(error: FacetrackingError.getCgImageError)
            return
        }
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            self.delegate?.error(error: FacetrackingError.getImageOrientationError)
            return
        }
        guard let requests = self.trackingRequests, !requests.isEmpty else {
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            visionFrameworkTaskQueue.async {
                do {
                    guard let detectRequests = self.detectionRequests else {
                        return
                    }
                    try imageRequestHandler.perform(detectRequests)
                } catch let error as NSError {
                    NSLog("Failed to perform FaceRectangleRequest: %@", error)
                }
            }
            return
        }
        visionFrameworkTaskQueue.async {
            do {
                try self.sequenceRequestHandler.perform(requests, on: ciImage, orientation: orientation)
            } catch let error as NSError {
                NSLog("Failed to perform SequenceRequest: %@", error)
            }
        }
        
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {
            guard let results = trackingRequest.results else {
                return
            }
            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests
        if newTrackingRequests.isEmpty {
            return
        }
    }
}
