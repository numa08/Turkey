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
    func tracking(_ source: Observable<UIImage>) -> Observable<VNDetectedObjectObservation?>
}

class FacetrackingService: FacetrackingServiceType, FaceTrackerDelegate {
    
    private let disposeBag = DisposeBag()
    private lazy var faceTrackingEventSubject = {
        return PublishSubject<VNDetectedObjectObservation?>()
    }()
    private lazy var faceTrackingEvent = {
        return faceTrackingEventSubject.share(replay: 1)
    }()
    private let tracker = FaceTracker()
    
    init() {
        tracker.delegate = self
    }
    
    func tracking(_ source: Observable<UIImage>) -> Observable<VNDetectedObjectObservation?> {
        source.subscribe(onNext: tracker.trackFace).disposed(by: disposeBag)
        return faceTrackingEvent
    }
    
    func error(error: Error) {
        faceTrackingEventSubject.onError(error)
    }
    
    func handleFacePosition(positions: [VNDetectedObjectObservation]) {
        if positions.isEmpty {
            faceTrackingEventSubject.onNext(nil)
        }
        positions.forEach(faceTrackingEventSubject.onNext)
    }
}
