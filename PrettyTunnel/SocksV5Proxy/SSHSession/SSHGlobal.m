//
//  SSHGlobal.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/6.
//
//

#import "SSHGlobal.h"
#import <libssh2/libssh2.h>

@implementation SSHGlobal

+ (void)load
{
	[SSHGlobal sharedInstance];
}

+ (instancetype)sharedInstance
{
	static SSHGlobal* obj;
	if (!obj)
		obj = [SSHGlobal new];
	
	return obj;
}

- (instancetype)init
{
	self = [super init];
	
	libssh2_init(0);
	
	return self;
}

- (void)dealloc
{
	libssh2_exit();
}

@end
