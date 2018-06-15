//
//  FaceTruckingService.swift
//  Turkey
//
//  Created by numa08 on 2018/06/11.
//  Copyright © 2018年 numa08. All rights reserved.
//

import Foundation
import Vision
import RxSwift

protocol FacetrackingServiceType {
    func tracking(_ source: Observable<UIImage>) -> Observable<VNDetectedObjectObservation>
}

class FacetrackingService: FacetrackingServiceType {
    
    enum FacetrackingError: Error {
        case getCgImageError

    }
    
    private let handler = VNSequenceRequestHandler()
    private var faceDetectedResults: [VNFaceObservation]?
    private let faceTrackingResultObserver = PublishSubject<VNDetectedObjectObservation>()
    private lazy var faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
        if let error = error {
            return
        }
        guard let req = request as? VNDetectFaceRectanglesRequest,
            let results = req.results as? [VNFaceObservation] else {
                return
        }
        if results.isEmpty {
            return
        }
        self.faceDetectedResults = results
    })
    private lazy var faceTrackingRequestHandler = {(request: VNRequest,error: Error?) in
        if let error = error {
            self.faceTrackingResultObserver.onError(error)
            return
        }
        guard let req = request as? VNTrackObjectRequest,
            let results = req.results as? [VNDetectedObjectObservation] else {
                return
        }
        results.forEach(self.faceTrackingResultObserver.onNext)
    }
    private let visionFrameworkQueue = DispatchQueue(label: "vision")
    
    func tracking(_ source: Observable<UIImage>) -> Observable<VNDetectedObjectObservation> {
        return source.map { image -> Observable<VNDetectedObjectObservation> in
            guard let ciImage = CIImage(image: image) else {
                return Observable.empty()
            }
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
            guard let faceDetectedResults = self.faceDetectedResults, !faceDetectedResults.isEmpty else {
                autoreleasepool {
                    self.detectFace(ciImage, orientation)
                }
                return Observable.empty()
            }
            return autoreleasepool {
                self.trackingFace(ciImage)
            }
        }.concat()
    }
    
    private func detectFace(_ image: CIImage, _ orientation: CGImagePropertyOrientation) {
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
        visionFrameworkQueue.async {
            try? handler.perform([self.faceDetectionRequest])
        }
    }
    
    private func trackingFace(_ image: CIImage) -> Observable<VNDetectedObjectObservation> {
        let requests = self.faceDetectedResults!.map { face -> VNTrackObjectRequest in
            return VNTrackObjectRequest(detectedObjectObservation: face, completionHandler: self.faceTrackingRequestHandler)
        }
        visionFrameworkQueue.async {
            try? self.handler.perform(requests, on: image)
        }
        return faceTrackingResultObserver.share(replay: 1)
    }
}
