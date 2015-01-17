//
//  KPLogFormatter.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-10-16.
//
//

#import "KPLogFormatter.h"

@implementation KPLogFormatter
{
	NSDateFormatter* _formatter;
}

- (NSString*)formatLogMessage:(DDLogMessage *)logMessage
{
	if (!_formatter)
	{
		_formatter = [[NSDateFormatter alloc] init];
		[_formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[_formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
	}

	NSString *dateAndTime = [_formatter stringFromDate:(logMessage->timestamp)];
    
    NSString *logLevel = nil;
    switch (logMessage->logFlag) {
        case DDLogFlagError     : logLevel = @"E"; break;
        case DDLogFlagWarning   : logLevel = @"W"; break;
        case DDLogFlagInfo      : logLevel = @"I"; break;
        case DDLogFlagDebug     : logLevel = @"D"; break;
		case DDLogFlagVerbose   : logLevel = @"V"; break;
        default                 : logLevel = @"?"; break;
    }
    
    NSString *formattedLog = [NSString stringWithFormat:@"%@\t %@\t %d:%d\t %@\t %@\t %@(%d)",
                              dateAndTime,
                              logLevel,
							  [[NSProcessInfo processInfo] processIdentifier],
							  logMessage->threadSeqNum,
							  logMessage->logMsg,
							  logMessage.methodName,
                              logMessage.fileName,
                              logMessage->lineNumber
                              ];
    
    return formattedLog;
}

@end
