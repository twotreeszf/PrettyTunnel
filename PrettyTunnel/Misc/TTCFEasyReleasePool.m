//
//  TTCFEasyRelease.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/16.
//
//

#import "TTCFEasyReleasePool.h"

@implementation TTCFEasyReleasePool
{
	NSMutableArray* _objs;
}

- (instancetype)init
{
	self = [super init];
	
	_objs = [NSMutableArray new];
	
	return self;
}

- (void)dealloc
{
	for (NSNumber* item in _objs)
	{
		CFTypeRef obj = (CFTypeRef)[item unsignedLongLongValue];
		CFRelease(obj);
	}
}

- (void)autorelease:(CFTypeRef)obj
{
	NSNumber* item = [NSNumber numberWithUnsignedLongLong:(unsigned long long)obj];
	[_objs addObject:item];
}


@end
