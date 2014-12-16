//
//  SOCKSProxy.h
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "SOCKSProxySocket.h"

@class SOCKSProxy;

@protocol SOCKSProxyDelegate <NSObject>
@optional
- (void) sshLoginFailed: (int)error;
- (void) sshLoginSuccessed;
- (void) sshSessionLost: (NSUInteger)index;

- (void) socksProxy:(SOCKSProxy*)socksProxy clientDidConnect:(SOCKSProxySocket*)clientSocket;
- (void) socksProxy:(SOCKSProxy*)socksProxy clientDidDisconnect:(SOCKSProxySocket*)clientSocket;
@end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

@interface SOCKSProxy : NSObject <GCDAsyncSocketDelegate, SOCKSProxySocketDelegate>

@property (nonatomic, weak) id<SOCKSProxyDelegate>	delegate;

@property (nonatomic, readonly) uint16_t			listeningPort;
@property (nonatomic, readonly) BOOL				connected;
@property(nonatomic, readonly)	NSString*			pacFileAddress;

@property (nonatomic, readonly) NSUInteger			connectionCount;
@property (nonatomic, readonly) NSUInteger			totalBytesWritten;
@property (nonatomic, readonly) NSUInteger			totalBytesRead;

- (void)startProxyWithRemoteHost:(NSString*)remoteHost
					  RemotePort:(uint16_t)remotePort
						UserName:(NSString*)userName
						Password:(NSString*)password
					   LocalPort:(uint16_t)localPort;
- (void)disconnect;
- (void)resetNetworkStatistics;

@end
