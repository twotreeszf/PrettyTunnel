//
//  SOCKSProxySocket.h
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "SSHSession/SSHSession.h"
#import "SSHProxyDelegate.h"

typedef NS_ENUM(NSUInteger, ProxySocketStatus)
{
	PSS_None = 0,
	PSS_InitLocalProxy,
	PSS_RequestNewChannel,
	PSS_ProxyReady,
	PSS_RequestCloseChannel
};

@class SOCKSProxySocket;

@interface SOCKSProxySocket : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, strong, readonly) NSString*						destinationHost;
@property (nonatomic, readonly)			uint16_t						destinationPort;
@property (nonatomic, readonly)			NSUInteger						totalBytesWritten;
@property (nonatomic, readonly)			NSUInteger						totalBytesRead;

@property (nonatomic, assign)			ProxySocketStatus				state;
@property (nonatomic, strong)			NSMutableArray*					writeDataQueue;
@property (nonatomic, weak)				id<SOCKSProxySocketDelegate>	delegate;
@property (nonatomic, readonly)			dispatch_queue_t				socketQueue;
@property (nonatomic, strong)			SSHChannel*						sshChannel;

- (id)initWithSocket:(GCDAsyncSocket*)socket delegate:(id<SOCKSProxySocketDelegate>)delegate;

- (void)relayConnctionReady;
- (void)relayRemoteData: (NSData*)data;
- (void)didWriteData: (NSUInteger)length;

@end
