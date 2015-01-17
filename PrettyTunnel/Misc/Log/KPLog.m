//
//  KPLog.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-10-16.
//
//

#import "KPLog.h"
#import "DDLog/DDLog.h"
#import "DDLog/DDTTYLogger.h"
#import "DDLog/DDASLLogger.h"
#import "DDLog/DDFileLogger.h"
#import "KPLogFormatter.h"


@implementation KPLog

+ (void)startup
{
	[[DDTTYLogger sharedInstance] setLogFormatter:[KPLogFormatter new]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	[[DDASLLogger sharedInstance] setLogFormatter:[KPLogFormatter new]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	/*
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
	[fileLogger setLogFormatter:[KPLogFormatter new]];
    [fileLogger setRollingFrequency: kSeconds1Day];
    [fileLogger setMaximumFileSize: 10 * kMegaByte];
    [fileLogger.logFileManager setMaximumNumberOfLogFiles:7];
	
    [DDLog addLogger:fileLogger];
	 */
}

@end

@implementation KPLogTraceStack
{
	const char* _file;
	const char* _function;
	int	_line;
}

- (instancetype)initWithFile: (const char*)file Function: (const char*)func Line: (int)line
{
	self = [super init];
	
	_file = file;
	_line = line;
	_function = func;
	
	[DDLog log:YES level:DDLogLevelVerbose flag:DDLogFlagVerbose context:0 file:_file function:_function line:_line tag:nil format:@"[IN]", nil];
	
	return self;
}

- (void)nothing
{
	
}

- (void)dealloc
{
	[DDLog log:YES level:DDLogLevelVerbose flag:DDLogFlagVerbose context:0 file:_file function:_function line:_line tag:nil format:@"[OUT]", nil];
}

@end