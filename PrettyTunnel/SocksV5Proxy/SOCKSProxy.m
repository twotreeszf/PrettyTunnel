//
//  SOCKSProxy.m
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "SOCKSProxy.h"
#import "SOCKSProxySocket.h"
#import "SSHProxy.h"

@interface SOCKSProxy ()

@property (nonatomic, strong) GCDAsyncSocket*	listeningSocket;
@property (nonatomic, strong) SSHProxy*			sshProxy;

@property (nonatomic) NSUInteger				totalBytesWritten;
@property (nonatomic) NSUInteger				totalBytesRead;

- (void)_startProxyOnPort:(uint16_t)port;

@end

@implementation SOCKSProxy

- (void)startProxyWithRemoteHost:(NSString*)remoteHost
					  RemotePort:(uint16_t)remotePort
						UserName:(NSString*)userName
						Password:(NSString*)password
					   LocalPort:(uint16_t)localPort;
{
	_sshProxy = [SSHProxy new];
	_sshProxy.delegate = self;
	
	[[NSOperationQueue globalQueue] addOperationWithBlock:^
	{
		int ret = LIBSSH2_ERROR_NONE;
		{
			ret = [_sshProxy connectToHost:remoteHost Port:remotePort Username:userName Password:password];
			ERROR_CHECK_BOOL(LIBSSH2_ERROR_NONE == ret);
			
			[self _startProxyOnPort:localPort];
		}
		
	Exit0:
		[[NSOperationQueue mainQueue] addOperationWithBlock:^
		{
			if (LIBSSH2_ERROR_NONE == ret && [_delegate respondsToSelector:@selector(sshLoginSuccessed)])
			{
				[_delegate sshLoginSuccessed];
			}
			else if ([_delegate respondsToSelector:@selector(sshLoginFailed:)])
			{
				[_delegate sshLoginFailed:ret];
			}
		}];
	}];
}

- (void)_startProxyOnPort:(uint16_t)port
{
    self.listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    _listeningPort = port;
	
    NSError* error = nil;
    [self.listeningSocket acceptOnPort:port error:&error];
    if (error)
    {
        NSLog(@"Error listening on port %d: %@", port, error.userInfo);
    }
    NSLog(@"Listening on port %d", port);
}

- (void)socket:(GCDAsyncSocket*)sock didAcceptNewSocket:(GCDAsyncSocket*)newSocket
{
	if (![_sshProxy connected])
	{
		[newSocket disconnect];
	}
	else
	{
		NSLog(@"Accepted new socket: %@", newSocket);
		#if TARGET_OS_IPHONE
		[newSocket performBlock:^{
			BOOL enableBackground = [newSocket enableBackgroundingOnSocket];
			if (!enableBackground) {
				NSLog(@"Error enabling background on new socket %@", newSocket);
			} else {
				NSLog(@"Backgrounding enabled for new socket: %@", newSocket);
			}
		}];
		#endif
		
		SOCKSProxySocket* proxySocket = [[SOCKSProxySocket alloc] initWithSocket:newSocket delegate:self];
		[_sshProxy attachProxySocket:proxySocket];
		
		if (self.delegate && [self.delegate respondsToSelector:@selector(socksProxy:clientDidConnect:)])
			[self.delegate socksProxy:self clientDidConnect:proxySocket];
	}
}

- (NSUInteger)connectionCount
{
	return _sshProxy.connectionCount;
}

- (void)disconnect
{
    [self.listeningSocket disconnect];
    self.listeningSocket = nil;
	
	[_sshProxy disconnect];
	
	[self resetNetworkStatistics];
}

- (void)proxySocketDidDisconnect:(SOCKSProxySocket*)proxySocket withError:(NSError*)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(socksProxy:clientDidDisconnect:)])
        [self.delegate socksProxy:self clientDidDisconnect:proxySocket];
}

- (void)sshSessionLost: (SSHProxy*)sshProxy
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(sshSessionLost:)])
		[self.delegate sshSessionLost:0];
}

- (void)proxySocket:(SOCKSProxySocket*)proxySocket didReadDataOfLength:(NSUInteger)numBytes
{
    self.totalBytesRead += numBytes;
}

- (void)proxySocket:(SOCKSProxySocket*)proxySocket didWriteDataOfLength:(NSUInteger)numBytes
{
    self.totalBytesWritten += numBytes;
}

- (void)resetNetworkStatistics
{
    self.totalBytesWritten = 0;
    self.totalBytesRead = 0;
}

@end
