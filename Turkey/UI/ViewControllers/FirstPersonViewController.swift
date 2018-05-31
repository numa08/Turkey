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

open class FirstPersonViewController:
UIViewController,
View {
    public var disposeBag: DisposeBag = DisposeBag()
    public typealias Reactor = FirstPersonReactor
    @IBOutlet weak var image: UIImageView!
    
    init(_ reactor: FirstPersonReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let reactor = reactor else {
            fatalError("reactor is nil")
        }
        
        Observable.just(Reactor.Action.connectDrone(port: "8090"))
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
    }
    
    public func bind(reactor: FirstPersonReactor) {
        reactor.state.asObservable().subscribe(onNext: {st in
            print("connected: \(st.connectionState)")
        })
        .disposed(by: disposeBag)
    }

}
