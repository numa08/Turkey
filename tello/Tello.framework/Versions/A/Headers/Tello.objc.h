// Objective-C API for talking to github.com/numa08/Turkey/tello Go package.
//   gobind -lang=objc github.com/numa08/Turkey/tello
//
// File is generated by gobind. Do not edit.

#ifndef __Tello_H__
#define __Tello_H__

@import Foundation;
#include "Universe.objc.h"


@protocol TelloConnectedEventHandler;
@class TelloConnectedEventHandler;
@protocol TelloVideoFrameEventHandler;
@class TelloVideoFrameEventHandler;

@protocol TelloConnectedEventHandler <NSObject>
- (void)conected;
@end

@protocol TelloVideoFrameEventHandler <NSObject>
- (void)videoFrame:(NSData*)p0;
@end

FOUNDATION_EXPORT void TelloInitDrone(NSString* port);

FOUNDATION_EXPORT BOOL TelloRegisterOnConnectedEvent(id<TelloConnectedEventHandler> callback, NSError** error);

FOUNDATION_EXPORT BOOL TelloRegisterVideoFrameEvent(id<TelloVideoFrameEventHandler> callback, NSError** error);

FOUNDATION_EXPORT BOOL TelloSetVideoEncoderRate(long rate, NSError** error);

FOUNDATION_EXPORT BOOL TelloStart(NSError** error);

FOUNDATION_EXPORT BOOL TelloStartVideo(NSError** error);

@class TelloConnectedEventHandler;

@class TelloVideoFrameEventHandler;

@interface TelloConnectedEventHandler : NSObject <goSeqRefInterface, TelloConnectedEventHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)conected;
@end

@interface TelloVideoFrameEventHandler : NSObject <goSeqRefInterface, TelloVideoFrameEventHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)videoFrame:(NSData*)p0;
@end

#endif