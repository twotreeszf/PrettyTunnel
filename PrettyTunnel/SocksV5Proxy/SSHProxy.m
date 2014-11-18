//
//  SSHProxy.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/18.
//
//

#import "SSHProxy.h"

@implementation SSHProxy
{
	SSHSession*		_ssh;
	NSMutableArray* _proxySockets;
}

- (instancetype)init
{
	self = [super init];
	
	_ssh			= [SSHSession new];
	_proxySockets	= [NSMutableArray new];
	
	return self;
}

- (NSUInteger)connectionCount
{
	return _proxySockets.count;
}

- (BOOL)connected
{
	return [_ssh isConnected];
}

- (int)connectToHost:(NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password
{
	return [_ssh connectToHost:host Port:port Username:username Password:password];
}

- (void)disconnect
{
	// stop ssh operation
	
	[_ssh disconnect];
	
	@synchronized (self)
	{
		[_proxySockets removeAllObjects];
	}
}

- (void)attachProxySocket: (SOCKSProxySocket*)socket
{
	@synchronized (self)
	{
		[_proxySockets addObject:socket];
	}
}

@end
