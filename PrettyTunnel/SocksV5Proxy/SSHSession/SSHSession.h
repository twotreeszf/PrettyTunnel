//
//  SSHSession.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/6.
//
//

#import <Foundation/Foundation.h>
#import "SSHChannel.h"
#import <libssh2/libssh2.h>


enum
{
	SSHSS_None		= 0,
	SSHSS_Read		= (1 << 0),
	SSHSS_Write		= (1 << 1),
	SSHSS_Except	= (1 << 2)
};
typedef NSUInteger SSHSessionStatus;

@interface SSHSession : NSObject

@property (nonatomic, copy, readonly) NSString* host;
@property (nonatomic, assign, readonly) UInt16	port;
@property (nonatomic, copy, readonly) NSString* userName;
@property (nonatomic, copy, readonly) NSString* password;

+ (BOOL)isSocketError:(int)error;
+ (BOOL)isChannelError:(int)error;

- (int)connectToHost: (NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password;
- (int)reconnect;
- (void)disconnect;
- (BOOL)isConnected;

- (SSHSessionStatus)waitSession:(SSHSessionStatus)waitStatus :(NSUInteger)timeoutMillisec;
- (int)lastError;

- (SSHChannel*)channelDirectTCPIPWithDestHost:(NSString*)destHost DestPort:(UInt16)destPort;

@end
