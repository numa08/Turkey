//
//  FirstPersonViewController.swift
//  Turkey
//
//  Created by numa08 on 2018/05/31.
//  Copyright © 2018年 numa08. All rights reserved.
//

import ReactorKit
import RxSwift
import RxCocoa
import RxOptional

open class FirstPersonViewController:
UIViewController,
StoryboardView {
    public var disposeBag: DisposeBag = DisposeBag()
    public typealias Reactor = FirstPersonReactor
    @IBOutlet weak var image: UIImageView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let reactor = reactor else {
            fatalError("reactor is nil")
        }
        
        Observable.just(Reactor.Action.connectDrone(port: "8090"))
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        Observable.just(Reactor.Action.startTracking(source: reactor
            .state
            .asObservable()
            .map { $0.frame }
            .filterNil()
        ))
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
    }
    
    public func bind(reactor: FirstPersonReactor) {
        reactor
            .state
            .map{$0.connectionState}
            .distinctUntilChanged()
            .filter{$0}
            .map({_ in Reactor.Action.startVideo(rate: 4)})
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        reactor
            .state
            .asObservable()
            .map{ $0.frame }
            .observeOn(OperationQueueScheduler(operationQueue: OperationQueue.main))
            .subscribe(onNext: {self.image?.image = $0})
            .disposed(by: disposeBag)
        reactor
            .state
            .asObservable()
            .map { $0.trackingResult }
            .filterNil()
            .subscribe(onNext: { print("detection result \($0)") })
            .disposed(by: disposeBag)
    }

}
