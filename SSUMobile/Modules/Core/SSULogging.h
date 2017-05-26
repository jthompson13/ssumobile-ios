//
//  SSULogging.h
//  SSUMobile
//
//  Created by Eric Amorde on 10/28/15.
//  Copyright © 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

@import Foundation;
#import <CocoaLumberjack/CocoaLumberjack.h>

//Note: this value must be named 'ddLogLevel', as the macros search for this symbol
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelError;
#endif

// http://stackoverflow.com/a/26364055
#ifdef DEBUG
#define SSULogError(fmt, ...)       DDLogError((@"%s [%d] \t" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define SSULogWarn(fmt, ...)        DDLogWarn((@"%s [%d] \t" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define SSULogInfo(fmt, ...)        DDLogInfo((@"%s [%d] \t" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define SSULogDebug(fmt, ...)       DDLogDebug((@"%s [%d] \t" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define SSULogVerbose(fmt, ...)     DDLogVerbose((@"%s [%d] \t" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define SSULogError(frmt, ...)      DDLogError(frmt, ##__VA_ARGS__)
#define SSULogWarn(frmt, ...)       DDLogWarn(frmt, ##__VA_ARGS__)
#define SSULogInfo(frmt, ...)       DDLogInfo(frmt, ##__VA_ARGS__)
#define SSULogDebug(frmt, ...)      DDLogDebug(frmt, ##__VA_ARGS__)
#define SSULogVerbose(frmt, ...)    DDLogVerbose(frmt, ##__VA_ARGS__)
#endif
