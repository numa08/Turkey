//
//  ImageDecoderService.swift
//  Turkey
//
//  Created by numa08 on 2018/05/31.
//  Copyright © 2018年 numa08. All rights reserved.
//

import RxSwift

protocol ImageDecoderServiceType {
    func decodeImage(source: Observable<Data>) -> Observable<UIImage>
}

class ImageDecoderService: NSObject,
ImageDecoderServiceType,
ImageDecoderDelegate {

    private let imageDecoder = ImageDecoder()
    private let disposeBag = DisposeBag()
    private lazy var decodeEventSubject = {
        return PublishSubject<UIImage>()
    }()
    private lazy var decodeEvent = {
        return decodeEventSubject.share(replay: 1)
    }()
    
    override init() {
        super.init()
        imageDecoder.delegate = self
        imageDecoder.open()
    }
    
    func decodeImage(source: Observable<Data>) -> Observable<UIImage> {
        source.subscribe(onNext: {self.imageDecoder.onNewFrame($0)}, onError:{ self.decodeEventSubject.onError($0)}).disposed(by: disposeBag)
        return decodeEvent
    }
    
    func decoder(_ decoder: ImageDecoder!, didDecode image: UIImage!) {
        decodeEventSubject.onNext(image)
    }
}
