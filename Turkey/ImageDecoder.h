//
//  CVImageDecorder.h
//  Turkey
//
//  Created by numa08 on 2018/05/10.
//  Copyright © 2018年 numa08. All rights reserved.
//
@class UIImage;
@class ImageDecoder;

@protocol ImageDecoderDelegate<NSObject>
- (void) decoder:(ImageDecoder*)decoder didDecodeImage:(UIImage*)image;
@end

@interface ImageDecoder : NSObject
@property (weak, nonatomic) id<ImageDecoderDelegate> delegate;
- (BOOL)open;
- (void)onNewFrame:(NSData*)frame;
- (void)close;
@end

