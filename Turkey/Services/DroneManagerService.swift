//
//  DronManagerService.swift
//  Turkey
//
//  Created by numa08 on 2018/05/31.
//  Copyright © 2018年 numa08. All rights reserved.
//

import RxSwift
import Tello

enum ConnectedStatus {
    case connected
    case disConnected
}

protocol DroneManagerServiceType {
    func startDrone(port: String) -> Observable<ConnectedStatus>
    func startVideo(rate: Int) -> Observable<Data>
    
}

class DroneManagerService: NSObject,
    DroneManagerServiceType,
TelloConnectedEventHandlerProtocol,
TelloVideoFrameEventHandlerProtocol{
    
    private lazy var droneConnectedEventSubject = {
        return PublishSubject<ConnectedStatus>()
    }()
    lazy var droneConnectedEvent = {
        return droneConnectedEventSubject.share(replay: 1)
    }()
    private lazy var droneVideoFrameEventSubject = {
        return PublishSubject<Data>()
    }()
    lazy var droneVideoFrameEvent = {
        return droneVideoFrameEventSubject.share(replay: 1)
    }()
    
    func startDrone(port: String)-> Observable<ConnectedStatus> {
        let obs = Observable<Void>.create({emitter in
            DispatchQueue(label: "tello").async {
                TelloInitDrone(port)
                var error: NSError?
                let drone = {(fn: (NSErrorPointer) -> ()) in
                    if error != nil {
                        return
                    }
                    fn(&error)
                }
                drone({TelloRegisterOnConnectedEvent(self, $0)})
                drone({TelloStart($0)})
                if let error = error {
                    emitter.onError(error)
                }
            }
            emitter.onNext(())
            return Disposables.create()
        }).share(replay: 1)
        return obs.flatMap({_ in self.droneConnectedEventSubject})
    }
    
    func startVideo(rate: Int) -> Observable<Data> {
        let obs = Observable<Void>.create({emitter in
            var error: NSError?
            let drone = {(fn: (NSErrorPointer) -> ()) in
                if error != nil {
                    return
                }
                fn(&error)
            }
            drone({ptr in TelloRegisterVideoFrameEvent(self, ptr)})
            drone({ptr in TelloSetVideoEncoderRate(rate, ptr)})
            drone({ptr in TelloStartVideo(ptr)})
            if let error = error {
                emitter.onError(error)
            } else {
                emitter.onNext(())
                emitter.onCompleted()
            }
            return Disposables.create()
        }).share(replay: 1)
        return obs.flatMap({_ in self.droneVideoFrameEventSubject})
    }
    
    func conected() {
        droneConnectedEventSubject.onNext(.connected)
    }
    
    func videoFrame(_ p0: Data!) {
        droneVideoFrameEventSubject.onNext(p0)
    }
}
