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

@interface SSHSession : NSObject

@property (nonatomic, copy, readonly) NSString* host;
@property (nonatomic, assign, readonly) UInt16	port;
@property (nonatomic, copy, readonly) NSString* userName;
@property (nonatomic, copy, readonly) NSString* password;

- (int)connectToHost: (NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password;
- (int)reconnect;
- (void)disconnect;
- (int)waitSession: (NSUInteger)timeoutSec;

- (SSHChannel*)channelDirectTCPIPWithSourceHost:(NSString*)sourceHost SourcePort:(UInt16)sourcePort DestHost:(NSString*)destHost DestPort:(UInt16)destPort;

@end
