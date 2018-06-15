//
//  FirstPersonReactor.swift
//  Turkey
//
//  Created by numa08 on 2018/05/31.
//  Copyright © 2018年 numa08. All rights reserved.
//

import Foundation
import ReactorKit
import RxSwift
import Vision

public final class FirstPersonReactor : Reactor {
    public let initialState: FirstPersonReactor.State
    let droneManagerService: DroneManagerServiceType
    let imageDecoderServce: ImageDecoderServiceType
    let trackingService: FacetrackingServiceType
    
    public enum Action {
        case connectDrone(port: String)
        case startVideo(rate: Int)
        case startTracking(source: Observable<UIImage>)
    }
    
    public enum Mutation {
        case connected(connectedStatus: Bool)
        case decodeImage(image: UIImage)
        case tracking(result: VNDetectedObjectObservation)
    }
    
    public struct State {
        var connectionState: Bool
        var frame: UIImage?
        var trackingResult: VNDetectedObjectObservation?
    }
    
    private let faceTrackingScheduler = SerialDispatchQueueScheduler(queue: DispatchQueue(label: "faceTracking"), internalSerialQueueName: "faceTracking")
    
    init(droneManagerService: DroneManagerServiceType, imageDecoderServce: ImageDecoderServiceType, trackingService: FacetrackingServiceType) {
        initialState = State(
            connectionState: false, frame: nil, trackingResult: nil
        )
        self.droneManagerService = droneManagerService
        self.imageDecoderServce = imageDecoderServce
        self.trackingService = trackingService
    }
    
    public func mutate(action: FirstPersonReactor.Action) -> Observable<FirstPersonReactor.Mutation> {
        switch action {
        case let .connectDrone(port):
            return droneManagerService.startDrone(port: port)
                .map({Mutation.connected(connectedStatus: $0 == .connected)})
        case let .startVideo(rate):
            return imageDecoderServce.decodeImage(source: droneManagerService.startVideo(rate: rate))
            .map({Mutation.decodeImage(image: $0)})
        case .startTracking(let source):
            return trackingService.tracking(source).map({Mutation.tracking(result: $0)}).subscribeOn(self.faceTrackingScheduler)
        }
    }
    
    public func reduce(state: FirstPersonReactor.State, mutation: FirstPersonReactor.Mutation) -> FirstPersonReactor.State {
        switch mutation {
        case let .connected(status):
            var newState = state
            newState.connectionState = status
            return newState
        case let .decodeImage(image):
            var newState = state
            newState.frame = image
            return newState
        case .tracking(let result):
            var newState = state
            newState.trackingResult = result
            return newState
        }
    }
}
