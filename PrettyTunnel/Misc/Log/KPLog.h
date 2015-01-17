//
//  KPLog.h
//  PrettyTunnel
//
//  Created by zhang fan on 14-10-16.
//
//

#import <Foundation/Foundation.h>

static const DDLogLevel ddLogLevel = LOG_LEVEL_VERBOSE;

@interface KPLog : NSObject

+ (void)startup;

@end

@interface KPLogTraceStack : NSObject

- (instancetype)initWithFile: (const char*)file Function: (const char*)func Line: (int)line;
- (void)nothing;

@end

#define KPTraceStack \
do\
{\
    if(ddLogLevel != DDLogLevelOff){\
	KPLogTraceStack* __traceStack_F8CB121C_AC90_4DE1_AC47_1CF1BCD7BFF7__ = [[KPLogTraceStack alloc] initWithFile:__FILE__ Function:__PRETTY_FUNCTION__ Line:__LINE__];\
	[__traceStack_F8CB121C_AC90_4DE1_AC47_1CF1BCD7BFF7__ nothing];\
}\
}\
while (0)
