# Trukey - Application for iOS

## Description

Turkey is experimental application for [Tji/RyzaTech Tello](https://www.ryzerobotics.com/jp/tello) and smartdevice (ex. iOS).

## Goal

@numa08 think ...

- share information about tello or someware.
- create interesting application.

## File structure

```bash
├── README.md # This file
├── Turkey # iOS Application
├── Turkey.xcodeproj
├── Vendor # dependencies
└── tello # native library
```

## How to build

### iOS

Turkey dependent to `ffmpeg` and `libx264`. You should build these libraries using [kewlbear/FFmpeg-iOS-build-script: Shell scripts to build FFmpeg for iOS and tvOS](https://github.com/kewlbear/FFmpeg-iOS-build-script) and [kewlbear/x264-ios: Script to build x264 for iOS apps](https://github.com/kewlbear/x264-ios).

These scripts create directories are named `FFmpeg-iOS` and `x264-iOS`.Then, move to `Vendor` directory.

And run iOS Appplication on your device.
