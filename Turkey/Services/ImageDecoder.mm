//
//  CVImageDecorder.m
//  Turkey
//
//  Created by numa08 on 2018/05/10.
//  Copyright © 2018年 numa08. All rights reserved.
//
#include <sys/types.h>
#include <sys/stat.h>
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavfilter/avfilter.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}
#import <CoreML/CoreML.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ImageDecoder.h"

@interface ImageDecoder()
{
    dispatch_queue_t writeFifoQueue;
}
@property NSPipe *fifoPipe;
@property BOOL captureRunning;
int read_frame(void *opaque, uint8_t *buf, int buf_size);
- (void)startCaptureThread;
- (void)captureInFFMpeg;
- (UIImage*)rgb24ToUIImage:(uint8_t*)pRgb width:(int)width height:(int)height wrap:(int)wrap;
@end

@implementation ImageDecoder

- (instancetype)init
{
    self = [super init];
    self.fifoPipe = [NSPipe pipe];
    return self;
}

- (BOOL)open
{
    self.captureRunning = YES;
    writeFifoQueue = dispatch_queue_create("write_fifo", DISPATCH_QUEUE_SERIAL);

    [self startCaptureThread];
    return YES;
}

- (void)onNewFrame:(NSData*)frame
{
    dispatch_async(writeFifoQueue, ^{
        [self.fifoPipe.fileHandleForWriting writeData:frame];
    });
 }

- (void)close
{
    self.captureRunning = NO;
}

-(void)startCaptureThread
{
    dispatch_queue_t queue = dispatch_queue_create("capture", nil);
    dispatch_async(queue, ^{
        [self captureInFFMpeg];
    });
}

int descriptor = 0;
int read_frame(void *opaque, uint8_t *buf, int buf_size)
{
    return (int)read(descriptor, buf, buf_size);
}

- (void)captureInFFMpeg
{
    av_register_all();
    avcodec_register_all();
    avfilter_register_all();
    
    descriptor = self.fifoPipe.fileHandleForReading.fileDescriptor;
    AVIOContext *avio_context;
    size_t avio_ctx_buffer_size = 4096;
    uint8_t *avio_ctx_buffer = (uint8_t*)av_malloc(avio_ctx_buffer_size);
    avio_context = avio_alloc_context(avio_ctx_buffer, (int)avio_ctx_buffer_size, 0, NULL, &read_frame, NULL, NULL);

    AVInputFormat *input_format = av_find_input_format("h264");
    AVFormatContext *format_context = avformat_alloc_context();
    format_context->pb = avio_context;
//    format_context->probesize = INT_MAX;
//    format_context->max_analyze_duration = INT_MAX;
    AVDictionary *format_dictionary = NULL;
    av_dict_set(&format_dictionary, "pixel_format", "yuv420p", 0);
    av_dict_set(&format_dictionary, "video_size", "960x720", 0);
    av_dict_set(&format_dictionary, "profile", "77", 0);
    av_dict_set(&format_dictionary, "fps", "25", 0);
    av_dict_set(&format_dictionary, "tbr", "25", 0);
    av_dict_set(&format_dictionary, "tbn", "1200k", 0);
    av_dict_set(&format_dictionary, "tbc", "50", 0);

    int ret;
    ret = avformat_open_input(&format_context, NULL, input_format, &format_dictionary);
    if (ret < 0) {
        char buf[1024];
        av_strerror(AVERROR(ret), buf, 1024);
        NSLog(@"avformat_open_input failed %s", buf);
        return;
    }
    
    ret = avformat_find_stream_info(format_context, &format_dictionary);
    if (ret < 0) {
        NSLog(@"avformat_find_stream_info failed: %08x", AVERROR(ret));
        return;
    }
    av_dump_format(format_context, 0, "", 0);
    int stream_index = av_find_best_stream(format_context, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (stream_index < 0) {
        NSLog(@"cound not find video stream");
        return;
    }
    AVStream *stream = format_context->streams[stream_index];

    // 読み込み用フレーム
    AVFrame *source_frame = av_frame_alloc();
    int source_width = stream->codecpar->width;
    int source_height = stream->codecpar->height;
    enum AVPixelFormat source_format = (AVPixelFormat)stream->codecpar->format;
    // RGB 変換用フレーム
    AVFrame *dest_frame = av_frame_alloc();
    int dest_width = stream->codecpar->width;
    int dest_height = stream->codecpar->height;
    enum AVPixelFormat dest_format = AV_PIX_FMT_RGB24;
    int dest_buffer_align = 32;
    uint8_t *dest_buffer = (uint8_t*)av_malloc(av_image_get_buffer_size(dest_format, dest_width, dest_height, dest_buffer_align));
    av_image_fill_arrays(dest_frame->data, dest_frame->linesize, dest_buffer, dest_format, dest_width, dest_height, dest_buffer_align);

    SwsContext *sws_context = sws_getContext(source_width, source_height, source_format, dest_width, dest_height, dest_format, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    
    AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (codec == NULL) {
        NSLog(@"cound not find codec for id %d", stream->codecpar->codec_id);
        return;
    }
    AVCodecContext *codec_context = avcodec_alloc_context3(codec);
    if (codec_context == NULL) {
        NSLog(@"avcodec_alloc_context3 failed");
        return;
    }
    if (avcodec_parameters_to_context(codec_context, stream->codecpar) < 0) {
        NSLog(@"avcodec_parameters_to_context failed");
        return;
    }
    if (avcodec_open2(codec_context, codec, NULL) < 0) {
        NSLog(@"avcodec_open2 failed");
        return;
    }
    
    AVPacket packet;
    while (av_read_frame(format_context, &packet) == 0 && self.captureRunning) {
        if (packet.stream_index == stream_index) {
            int ret;
            ret = avcodec_send_packet(codec_context, &packet);
            if (ret != 0) {
                char buf[1024];
                av_strerror(AVERROR(ret), buf, 1024);
                NSLog(@"avcodec_send_packet failed, %s", buf);
            }
            
            while (avcodec_receive_frame(codec_context, source_frame) == 0) {
                sws_scale(sws_context, source_frame->data, source_frame->linesize, 0, source_height, dest_frame->data, dest_frame->linesize);
                UIImage * image = [self rgb24ToUIImage:dest_frame->data[0] width:dest_width height:dest_height wrap:dest_frame->linesize[0]];
                [self.delegate decoder:self didDecodeImage:image];
            }
        }
        av_packet_unref(&packet);
    }
    sws_freeContext(sws_context);
    avcodec_free_context(&codec_context);
    av_frame_free(&dest_frame);
    av_frame_free(&source_frame);
    avformat_free_context(format_context);
}

- (UIImage*)rgb24ToUIImage:(uint8_t*)pRgb width:(int)width height:(int)height wrap:(int)wrap
{
    // RGB24 -> RGBA32 pixelデータ転送。
    uint8_t* pRgba = (uint8_t*)malloc(width * height * 4);
    for (int y = 0; y < height; ++y) {
        int si = y * wrap;
        int di = y * width * 4;
        for (int x = 0; x < width; ++x) {
            pRgba[di + 0] = pRgb[si + 0];
            pRgba[di + 1] = pRgb[si + 1];
            pRgba[di + 2] = pRgb[si + 2];
            pRgba[di + 3] = UINT8_MAX;
            si += 3;
            di += 4;
        }
    }
    
    // UIImage作成。
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pRgba, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
    UIImage* uiimage = [[UIImage alloc] initWithCGImage:cgimage];
    CGImageRelease(cgimage);
    CGContextRelease(ctx);
    free(pRgba);
    return uiimage;
}

@end
