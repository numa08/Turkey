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
    
    private lazy var rectangleView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = UIColor.clear
        self.image.addSubview(view)
        return view
    }()
    
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
            .subscribe(onNext: {result in
                let view = self.rectangleView
                view.layer.borderColor = UIColor.green.cgColor
                view.frame = self.transformRect(fromRect: result.boundingBox, toViewRect: self.image)
            })
            .disposed(by: disposeBag)
        reactor
            .state
            .asObservable()
            .map { $0.trackingResult }
            .filter { $0 == nil }
            .subscribe(onNext: {_ in
                self.rectangleView.layer.borderColor = UIColor.clear.cgColor
            })
            .disposed(by: disposeBag)
    }

    //Convert Vision Frame to UIKit Frame
    func transformRect(fromRect: CGRect , toViewRect :UIView) -> CGRect {
        
        var toRect = CGRect()
        toRect.size.width = fromRect.size.width * toViewRect.frame.size.width
        toRect.size.height = fromRect.size.height * toViewRect.frame.size.height
        toRect.origin.y =  (toViewRect.frame.height) - (toViewRect.frame.height * fromRect.origin.y )
        toRect.origin.y  = toRect.origin.y -  toRect.size.height
        toRect.origin.x =  fromRect.origin.x * toViewRect.frame.size.width
        
        return toRect
    }
}
