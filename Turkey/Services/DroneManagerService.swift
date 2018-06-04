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
                do {
                    let _ = try errorToThrow({TelloRegisterOnConnectedEvent(self, $0)})
                    let _ = try errorToThrow({TelloStart($0)})
                } catch {
                    emitter.onError(error)
                }
            }
            emitter.onNext(())
            return Disposables.create()
        }).share(replay: 1)
        return obs.flatMap({_ in self.droneConnectedEventSubject}).share(replay: 1)
    }
    
    func startVideo(rate: Int) -> Observable<Data> {
        let obs = Observable<Void>.create({emitter in
            do {
                let _ = try errorToThrow({TelloRegisterVideoFrameEvent(self, $0)})
                let _ = try errorToThrow({TelloSetVideoEncoderRate(rate, $0)})
                let _ = try errorToThrow({TelloStartVideo($0)})
                emitter.onNext(())
            } catch {
                emitter.onError(error)
            }
            return Disposables.create()
        }).share(replay: 1)
        return obs.flatMap({_ in self.droneVideoFrameEventSubject}).share(replay: 1)
    }
    
    func conected() {
        droneConnectedEventSubject.onNext(.connected)
    }
    
    func videoFrame(_ p0: Data!) {
        droneVideoFrameEventSubject.onNext(p0)
    }
}
