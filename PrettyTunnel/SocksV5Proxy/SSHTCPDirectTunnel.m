//
//  SSHProxy.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/18.
//
//

#import "SSHTCPDirectTunnel.h"

#define kCreateChannelTimeout				30.0

@interface SSHTCPDirectTunnel()
{
	SSHSession*		_ssh;
	NSMutableArray* _proxySockets;
	NSOperation*	_proxyOperation;
}

- (void)_startProxyOperation;

@end

@implementation SSHTCPDirectTunnel

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
		[self _startProxyOperation];
	
	return ret;
}

- (int)reconnect
{
	int ret = [_ssh reconnect];
	if (LIBSSH2_ERROR_NONE == ret)
		[self _startProxyOperation];
	
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
		while (!weakOpt.isCancelled)
		{
			@autoreleasepool
			{
				// copy sockets and prepare state
				NSMutableArray* proxySockets;
				@synchronized (self)
				{
					proxySockets = [_proxySockets copy];
				}
				
				BOOL needRead	= NO;
				for (SOCKSProxySocket* sock in proxySockets)
				{
					if (PSS_ProxyReady == sock.state)
					{
						needRead = YES;
						break;
					}
				}
				
				BOOL needWrite	= NO;
				for (SOCKSProxySocket* sock in proxySockets)
				{
					if ((PSS_RequestNewChannel == sock.state) || (PSS_RequestCloseChannel == sock.state))
					{
						needWrite = YES;
						break;
					}
					
					@synchronized (sock.writeDataQueue)
					{
						if (sock.writeDataQueue.count)
						{
							needWrite = YES;
							break;
						}
					}
				}
				
				SSHSessionStatus waitStatus = SSHSS_Except;
				if (needRead)
					waitStatus |= SSHSS_Read;
				if (needWrite)
					waitStatus |= SSHSS_Write;
				SSHSessionStatus currentStatus = [_ssh waitSession:waitStatus :100];
				
				NSMutableArray* socketsShouldClose = [NSMutableArray new];
				
				// connection error
				if (currentStatus & SSHSS_Except)
					break;
				
				// try to read channels
				if (currentStatus & SSHSS_Read)
				{
					for (SOCKSProxySocket* sock in proxySockets)
					{
						if (weakOpt.cancelled)
							break;
						
						@autoreleasepool
						{
							if (PSS_ProxyReady == sock.state)
							{
								X_ASSERT(sock.sshChannel);
								
								int error = LIBSSH2_ERROR_NONE;
								NSData* data = [sock.sshChannel read:&error];
								if (data)
								{
									[sock relayRemoteData:data];
								}
								else if ((LIBSSH2_ERROR_NONE != error) && (LIBSSH2_ERROR_EAGAIN != error))
								{
									[sock disconnectLocal];
									[socketsShouldClose addObject:sock];
								}
							}
						}
					}
				}
				
				// try to create channel, close channel and write channel
				if (currentStatus & SSHSS_Write)
				{
					for (SOCKSProxySocket* sock in proxySockets)
					{
						if (weakOpt.cancelled)
							break;
						
						if (PSS_RequestCloseChannel == sock.state)
						{
							if (sock.sshChannel)
							{
								int ret = [sock.sshChannel close];
								X_ASSERT(LIBSSH2_ERROR_NONE == ret);								
							}
							
							[socketsShouldClose addObject:sock];
						}
						else if (PSS_RequestNewChannel == sock.state)
						{
							X_ASSERT(sock.destinationHost.length);
							X_ASSERT(sock.destinationPort);
							
							// start create channel
							if (!sock.createChannelStartTime)
								sock.createChannelStartTime = [NSDate date];

							// try create channel
							NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:sock.createChannelStartTime];
							if (timeInterval < kCreateChannelTimeout)
							{
								sock.sshChannel = [_ssh channelDirectTCPIPWithDestHost:sock.destinationHost DestPort:sock.destinationPort];
								if (sock.sshChannel)
								{
									sock.state = PSS_ProxyReady;
									[sock relayConnctionReady];
								}

							}
							// create TCP direct channel fail, meybe couldn't connect dest host on remote server, force close local socket
							else
							{
								[sock disconnectLocal];
								[socketsShouldClose addObject:sock];
							}
						}
						else if (PSS_ProxyReady == sock.state)
						{
							while (true)
							{
								if (weakOpt.cancelled)
									break;
								
								NSData* dataToWrite;
								@synchronized(sock.writeDataQueue)
								{
									dataToWrite = [sock.writeDataQueue head];
									if (!dataToWrite)
										break;
								}
								
								X_ASSERT(dataToWrite.length);
								
								int error = LIBSSH2_ERROR_NONE;
								int writeLength = [sock.sshChannel write:dataToWrite :&error];
								if (error > 0 || LIBSSH2_ERROR_NONE == error || LIBSSH2_ERROR_EAGAIN == error)
								{
									[[NSOperationQueue mainQueue] addOperationWithBlock:^
									 {
										 [_delegate proxySocket:sock didWriteDataOfLength:writeLength];
									 }];

									@synchronized(sock.writeDataQueue)
									{
										if (writeLength == dataToWrite.length)
											[sock.writeDataQueue dequeue];
										else if (writeLength)
											sock.writeDataQueue[0] = [dataToWrite subdataWithRange:NSMakeRange(writeLength, dataToWrite.length - writeLength)];
									}
								}
								else
								{
									[sock disconnectLocal];
									[socketsShouldClose addObject:sock];
								}
								
								if (dataToWrite.length != writeLength)
									break;
							}
						}
					}
				}
				
				// remove disconnected sockets
				if (socketsShouldClose.count)
				{
					@synchronized(self)
					{
						for (SOCKSProxySocket* sock in socketsShouldClose)
						{
							[sock didClosed];
							[_proxySockets removeObject:sock];
						}
					}				
				}
			}
		}
		
		if (!weakOpt.isCancelled)
		{
			if (_delegate && [_delegate respondsToSelector:@selector(sshSessionLost:)])
			{
				[[NSOperationQueue mainQueue] addOperationWithBlock:^
				{
					[_delegate sshSessionLost:self];
				}];
			}
		}
	}];
	
	[[NSOperationQueue globalQueue] addOperation:opt];
	_proxyOperation = opt;
}

@end
