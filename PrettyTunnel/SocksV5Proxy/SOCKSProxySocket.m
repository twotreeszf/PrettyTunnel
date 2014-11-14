//
//  SOCKSProxySocket.m
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

// Define various socket tags
#define SOCKS_OPEN 10100
#define SOCKS_CONNECT_INIT 10200
#define SOCKS_CONNECT_IPv4 10201
#define SOCKS_CONNECT_DOMAIN 10202
#define SOCKS_CONNECT_DOMAIN_LENGTH 10212
#define SOCKS_CONNECT_IPv6 10203
#define SOCKS_CONNECT_PORT 10210
#define SOCKS_CONNECT_REPLY 10300
#define SOCKS_INCOMING_READ 10400
#define SOCKS_INCOMING_WRITE 10401

// Timeouts
#define TIMEOUT_CONNECT 8.00
#define TIMEOUT_READ 5.00
#define TIMEOUT_TOTAL 80.00

#import "SOCKSProxySocket.h"
#include <arpa/inet.h>

@interface SOCKSProxySocket ()
@property (nonatomic, weak) SSHSession*			sshSession;
@property (nonatomic, strong) SSHChannel*		sshChannel;
@property (nonatomic, strong) NSOperation*		sshOperation;
@property (nonatomic, assign) BOOL				isCancel;

@property (nonatomic, strong) GCDAsyncSocket*	proxySocket;
@property (nonatomic) dispatch_queue_t			delegateQueue;
@property (nonatomic) NSUInteger				totalBytesWritten;
@property (nonatomic) NSUInteger				totalBytesRead;
@end

@implementation SOCKSProxySocket

- (id) initWithSocket:(GCDAsyncSocket*)socket SSHSession:(SSHSession*)sshSession delegate:(id<SOCKSProxySocketDelegate>)delegate;
{
    if (self = [super init])
    {
		_sshSession	= sshSession;
        _delegate = delegate;
		
        self.delegateQueue = dispatch_queue_create("SOCKSProxySocket socket delegate queue", 0);
		self.callbackQueue = dispatch_get_main_queue();
		
        self.proxySocket = socket;
        self.proxySocket.delegate = self;
        self.proxySocket.delegateQueue = self.delegateQueue;
		
        [self socksOpen];
    }
    return self;
}

- (void)dealloc
{
	[_proxySocket disconnect];
	[_sshOperation waitUntilFinished];
}

- (void)socket:(GCDAsyncSocket*)sock
    didReadData:(NSData*)data
        withTag:(long)tag
{
    if (tag == SOCKS_OPEN)
    {
        //      +-----+--------+
        // NAME | VER | METHOD |
        //      +-----+--------+
        // SIZE |  1  |   1    |
        //      +-----+--------+
        //
        // Note: Size is in bytes
        //
        // Version = 5 (for SOCKS5)
        // Method  = 0 (No authentication, anonymous access)
        NSUInteger responseLength = 2;
        uint8_t* responseBytes = malloc(responseLength * sizeof(uint8_t));
        responseBytes[0] = 5; // VER = SOCKS5
        responseBytes[1] = 0; // METHOD = No Auth
        NSData* responseData = [NSData dataWithBytesNoCopy:responseBytes length:responseLength freeWhenDone:YES];
        [sock writeData:responseData withTimeout:-1 tag:SOCKS_OPEN];
        [sock readDataToLength:4 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_INIT];
    }
    else if (tag == SOCKS_CONNECT_INIT)
    {
        //      +-----+-----+-----+------+------+------+
        // NAME | VER | CMD | RSV | ATYP | ADDR | PORT |
        //      +-----+-----+-----+------+------+------+
        // SIZE |  1  |  1  |  1  |  1   | var  |  2   |
        //      +-----+-----+-----+------+------+------+
        //
        // Note: Size is in bytes
        //
        // Version      = 5 (for SOCKS5)
        // Command      = 1 (for Connect)
        // Reserved     = 0
        // Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
        // Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
        // Port         = 0
        uint8_t* requestBytes = (uint8_t*)[data bytes];
        uint8_t addressType = requestBytes[3];
        if (addressType == 1)
        {
            [sock readDataToLength:4 withTimeout:-1 tag:SOCKS_CONNECT_IPv4];
        }
        else if (addressType == 3)
        {
            [sock readDataToLength:1 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_DOMAIN_LENGTH];
        }
        else if (addressType == 4)
        {
            [sock readDataToLength:16 withTimeout:-1 tag:SOCKS_CONNECT_IPv6];
        }
    }
    else if (tag == SOCKS_CONNECT_IPv4)
    {
        uint8_t* address = malloc(INET_ADDRSTRLEN * sizeof(uint8_t));
        inet_ntop(AF_INET, data.bytes, (char*)address, INET_ADDRSTRLEN);
        _destinationHost = [[NSString alloc] initWithBytesNoCopy:address length:INET_ADDRSTRLEN encoding:NSUTF8StringEncoding freeWhenDone:YES];
        [sock readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_IPv6)
    {
        uint8_t* address = malloc(INET6_ADDRSTRLEN * sizeof(uint8_t));
        inet_ntop(AF_INET6, data.bytes, (char*)address, INET6_ADDRSTRLEN);
        _destinationHost = [[NSString alloc] initWithBytesNoCopy:address length:INET6_ADDRSTRLEN encoding:NSUTF8StringEncoding freeWhenDone:YES];
        [sock readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_DOMAIN)
    {
        _destinationHost = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [sock readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_DOMAIN_LENGTH)
    {
        uint8_t* bytes = (uint8_t*)data.bytes;
        uint8_t addressLength = bytes[0];
        [sock readDataToLength:addressLength withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_DOMAIN];
    }
    else if (tag == SOCKS_CONNECT_PORT)
    {
		// create channel for current proxy socket
        uint16_t rawPort;
        memcpy(&rawPort, [data bytes], 2);
        _destinationPort = NSSwapBigShortToHost(rawPort);
		
		_sshChannel = [_sshSession channelDirectTCPIPWithSourceHost:_proxySocket.localHost
														 SourcePort:_proxySocket.localPort
														   DestHost:_destinationHost
														   DestPort:_destinationPort];
		// SSH failed
		if (!_sshChannel)
		{
			if (self.delegate && [self.delegate respondsToSelector:@selector(sshSessionFailed)])
			{
				dispatch_async(self.callbackQueue, ^{
					[self.delegate sshSessionFailed];
				});
			}
		}
		else
		{
			// send response to proxy socket
			
			// We write out 5 bytes which we expect to be:
			// 0: ver  = 5
			// 1: rep  = 0
			// 2: rsv  = 0
			// 3: atyp = 3
			// 4: size = size of addr field
			NSUInteger responseLength = 5 + _destinationHost.length + 2;
			uint8_t* responseBytes = malloc(responseLength * sizeof(uint8_t));
			responseBytes[0] = 5;
			responseBytes[1] = 0;
			responseBytes[2] = 0;
			responseBytes[3] = 3;
			responseBytes[4] = (uint8_t)_destinationHost.length;
			memcpy(responseBytes + 5, [_destinationHost UTF8String], _destinationHost.length);
			uint16_t bigEndianPort = NSSwapHostShortToBig(_destinationPort);
			NSUInteger portLength = 2;
			memcpy(responseBytes + 5 + _destinationHost.length, &bigEndianPort, portLength);
			NSData* responseData = [NSData dataWithBytesNoCopy:responseBytes length:responseLength freeWhenDone:YES];
			[self.proxySocket writeData:responseData withTimeout:-1 tag:SOCKS_CONNECT_REPLY];
			[self.proxySocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
			
			// start read channel operation
			NSBlockOperation* opt = [NSBlockOperation new];
			[opt addExecutionBlock:^{
				[self readChannel];
			}];
			
			[[NSOperationQueue globalQueue] addOperation:opt];
			_sshOperation = opt;
		}
    }
    else if (tag == SOCKS_INCOMING_READ)
    {
		// write data from proxy socket to SSH channel
		int ret = [_sshChannel write:data];
		if (ret > 0)
		{
			[self.proxySocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
			NSUInteger dataLength = data.length;
			self.totalBytesWritten += dataLength;
			if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didWriteDataOfLength:)])
			{
				dispatch_async(self.callbackQueue, ^{
					[self.delegate proxySocket:self didWriteDataOfLength:dataLength];
				});
			}
		}
		else
		{
			if([SSHSession isSocketError:ret])
			{
				if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didWriteDataOfLength:)])
				{
					dispatch_async(self.callbackQueue, ^{
						[self.delegate sshSessionFailed];
					});
				}
			}
			
			[_proxySocket disconnect];
		}
    }
}

- (void)socksOpen
{
    //      +-----+-----------+---------+
    // NAME | VER | NMETHODS  | METHODS |
    //      +-----+-----------+---------+
    // SIZE |  1  |    1      | 1 - 255 |
    //      +-----+-----------+---------+
    //
    // Note: Size is in bytes
    //
    // Version    = 5 (for SOCKS5)
    // NumMethods = 1
    // Method     = 0 (No authentication, anonymous access)
    [self.proxySocket readDataToLength:3 withTimeout:TIMEOUT_CONNECT tag:SOCKS_OPEN];
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err
{
	[_sshChannel close];
	_isCancel = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocketDidDisconnect:withError:)])
    {
        dispatch_async(self.callbackQueue, ^{
			[self.delegate proxySocketDidDisconnect:self withError:err];
        });
    }
}

- (void)readChannel
{
	while (![_sshChannel isEOF] && !_isCancel)
	{
		@autoreleasepool
		{
			NSData* data;
			int ret = [_sshChannel read:&data];
			if (LIBSSH2_ERROR_EAGAIN == ret || 0 == ret)
			{
				[_sshChannel waitSession];
				continue;
			}
			
			// read data failed
			if (!data)
			{
				if([SSHSession isSocketError:ret])
				{
					if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didWriteDataOfLength:)])
					{
						dispatch_async(self.callbackQueue, ^{
							[self.delegate sshSessionFailed];
						});
					}
				}
				
				[_proxySocket disconnect];
				break;
			}
			
			// read data success
			dispatch_async(_delegateQueue, ^
						   {
							   [self.proxySocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
							   
							   NSUInteger dataLength = data.length;
							   self.totalBytesRead += dataLength;
							   
							   if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didReadDataOfLength:)])
							   {
								   dispatch_async(self.callbackQueue, ^{
									   [self.delegate proxySocket:self didReadDataOfLength:dataLength];
								   });
							   }
						   });
		}
	}
}

@end
