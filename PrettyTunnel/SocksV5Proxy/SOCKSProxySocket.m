//
//  SOCKSProxySocket.m
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

// Define various socket tags
#define SOCKS_OPEN					10100
#define SOCKS_CONNECT_INIT			10200
#define SOCKS_CONNECT_IPv4			10201
#define SOCKS_CONNECT_DOMAIN		10202
#define SOCKS_CONNECT_DOMAIN_LENGTH 10212
#define SOCKS_CONNECT_IPv6			10203
#define SOCKS_CONNECT_PORT			10210
#define SOCKS_CONNECT_REPLY			10300
#define SOCKS_INCOMING_READ			10400
#define SOCKS_INCOMING_WRITE		10401

// Timeouts
#define TIMEOUT_LOCAL_READ	5.00
#define TIMEOUT_TOTAL		80.00

#import "SOCKSProxySocket.h"
#include <arpa/inet.h>

@interface SOCKSProxySocket ()
{
	GCDAsyncSocket*		_proxySocket;
	dispatch_queue_t	_socketQueue;
}
@end

@implementation SOCKSProxySocket

- (NSString*)localHost
{
	NSString* host = _proxySocket.connectedHost;
	return host ? host : @"";
}

- (uint16_t)localPort
{
	return _proxySocket.connectedPort;
}

- (id) initWithSocket:(GCDAsyncSocket*)socket delegate:(id<SOCKSProxySocketDelegate>)delegate;
{
    if (self = [super init])
    {
        _delegate = delegate;
		
        _socketQueue = dispatch_get_main_queue();
		
        _proxySocket = socket;
        _proxySocket.delegate = self;
        _proxySocket.delegateQueue = _socketQueue;
		
		_state = PSS_InitLocalProxy;
		_writeDataQueue = [NSMutableArray new];
		
        [self socksOpen];
    }
    return self;
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
        [sock readDataToLength:4 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_INIT];
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
            [sock readDataToLength:1 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_DOMAIN_LENGTH];
        }
        else if (addressType == 4)
        {
            [sock readDataToLength:16 withTimeout:-1 tag:SOCKS_CONNECT_IPv6];
        }
    }
    else if (tag == SOCKS_CONNECT_IPv4)
    {
        char* address = malloc(INET_ADDRSTRLEN * sizeof(uint8_t));
        inet_ntop(AF_INET, data.bytes, (char*)address, INET_ADDRSTRLEN);
		_destinationHost = [NSString stringWithUTF8String:address];
		free(address);
		
        [sock readDataToLength:2 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_IPv6)
    {
        char* address = malloc(INET6_ADDRSTRLEN * sizeof(uint8_t));
        inet_ntop(AF_INET6, data.bytes, (char*)address, INET6_ADDRSTRLEN);
        _destinationHost = [NSString stringWithUTF8String:address];
		free(address);
		
        [sock readDataToLength:2 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_DOMAIN)
    {
        _destinationHost = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [sock readDataToLength:2 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_PORT];
    }
    else if (tag == SOCKS_CONNECT_DOMAIN_LENGTH)
    {
        uint8_t* bytes = (uint8_t*)data.bytes;
        uint8_t addressLength = bytes[0];
        [sock readDataToLength:addressLength withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_CONNECT_DOMAIN];
    }
    else if (tag == SOCKS_CONNECT_PORT)
    {
		// create channel for current proxy socket
        uint16_t rawPort;
        memcpy(&rawPort, [data bytes], 2);
        _destinationPort = NSSwapBigShortToHost(rawPort);
		
		_state = PSS_RequestNewChannel;
    }
    else if (tag == SOCKS_INCOMING_READ)
    {
		@synchronized (_writeDataQueue)
		{
			[_writeDataQueue enqueue:data];
		}
		
		[_proxySocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
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
    [_proxySocket readDataToLength:3 withTimeout:TIMEOUT_LOCAL_READ tag:SOCKS_OPEN];
}

- (void)relayConnctionReady
{
	dispatch_async(_socketQueue, ^
	{
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
		[_proxySocket writeData:responseData withTimeout:-1 tag:SOCKS_CONNECT_REPLY];
		[_proxySocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];		
	});
}

- (void)relayRemoteData:(NSData*)data
{
    dispatch_async(_socketQueue, ^
	{
		[_proxySocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
		NSUInteger dataLength = data.length;
		_totalBytesRead += dataLength;
	 
		if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didReadDataOfLength:)])
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.delegate proxySocket:self didReadDataOfLength:dataLength];
			});
		}
    });
}

- (void)disconnectLocal
{
	dispatch_async(_socketQueue, ^
	{
		[_proxySocket disconnect];
	});
}

- (void)didClosed
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocketDidDisconnect:withError:)])
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate proxySocketDidDisconnect:self withError:nil];
		});
	}
}

- (void)didWriteData:(NSUInteger)length
{
	dispatch_async(_socketQueue, ^
	{
		_totalBytesRead += length;
		 
		if (self.delegate && [self.delegate respondsToSelector:@selector(proxySocket:didReadDataOfLength:)])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate proxySocket:self didReadDataOfLength:length];
			});
		}
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err
{
	_state = PSS_RequestCloseChannel;
}

@end
