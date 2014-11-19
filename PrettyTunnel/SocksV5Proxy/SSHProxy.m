//
//  SSHProxy.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/18.
//
//

#import "SSHProxy.h"

@interface SSHProxy()
{
	SSHSession*		_ssh;
	NSMutableArray* _proxySockets;
	NSOperation*	_proxyOperation;
}

- (void)_startProxyOperation;

@end

@implementation SSHProxy

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
	int ret = [_ssh connectToHost:host Port:port Username:username Password:password];
	if (LIBSSH2_ERROR_NONE == ret)
	{
		
	}
	
	return ret;
}

- (void)disconnect
{
	[_proxyOperation cancel];
	[_proxyOperation waitUntilFinished];
	_proxyOperation = nil;
	
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

- (void)_startProxyOperation
{
	NSBlockOperation* opt = [NSBlockOperation new];
	__weak NSBlockOperation* weakOpt = opt;
	[opt addExecutionBlock:^
	{
		;
	}];
	
	[[NSOperationQueue globalQueue] addOperation:opt];
	_proxyOperation = opt;
}

@end
