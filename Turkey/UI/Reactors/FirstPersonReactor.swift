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

public final class FirstPersonReactor : Reactor {
    public let initialState: FirstPersonReactor.State
    let droneManagerService: DroneManagerServiceType
    let imageDecoderServce: ImageDecoderServiceType
    
    public enum Action {
        case connectDrone(port: String)
        case startVideo(rate: Int)
    }
    
    public enum Mutation {
        case connected(connectedStatus: Bool)
        case decodeImage(image: UIImage)
    }
    
    public struct State {
        var connectionState: Bool
        var frame: UIImage?
    }
    
    init(droneManagerService: DroneManagerServiceType, imageDecoderServce: ImageDecoderServiceType) {
        initialState = State(
            connectionState: false, frame: nil
        )
        self.droneManagerService = droneManagerService
        self.imageDecoderServce = imageDecoderServce
    }
    
    public func mutate(action: FirstPersonReactor.Action) -> Observable<FirstPersonReactor.Mutation> {
        switch action {
        case let .connectDrone(port):
            return droneManagerService.startDrone(port: port)
                .map({Mutation.connected(connectedStatus: $0 == .connected)})
        case let .startVideo(rate):
            return imageDecoderServce.decodeImage(source: droneManagerService.startVideo(rate: rate))
            .map({Mutation.decodeImage(image: $0)})
        }
    }
    
    public func reduce(state: FirstPersonReactor.State, mutation: FirstPersonReactor.Mutation) -> FirstPersonReactor.State {
        var state = state
        switch mutation {
        case let .connected(status):
            state.connectionState = status
        case let .decodeImage(image):
            state.frame = image
        }
        return state
    }
}
