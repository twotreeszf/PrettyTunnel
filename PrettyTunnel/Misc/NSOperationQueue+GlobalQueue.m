//
//  NSOperationQueue+GlobalQueue.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-8-5.
//
//

#import "NSOperationQueue+GlobalQueue.h"

@implementation NSOperationQueue (GlobalQueue)

+ (instancetype)globalQueue
{
	static NSOperationQueue* globalQueue;
	
	static dispatch_once_t token;
	dispatch_once(&token, ^
	{
		globalQueue = [NSOperationQueue new];
	});
	
	return globalQueue;
}

@end
