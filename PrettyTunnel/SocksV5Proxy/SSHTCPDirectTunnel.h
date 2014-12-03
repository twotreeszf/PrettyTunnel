//
//  SSHProxy.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/18.
//
//

#import <Foundation/Foundation.h>
#import "SSHSession/SSHSession.h"
#import "SOCKSProxySocket.h"
#import "SSHProxyDelegate.h"

@interface SSHTCPDirectTunnel : NSObject

@property (nonatomic, weak) id<SOCKSProxySocketDelegate> delegate;
@property (nonatomic, readonly) NSUInteger connectionCount;
@property (nonatomic, readonly) BOOL connected;

- (int)connectToHost:(NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password;
- (int)reconnect;
- (void)disconnect;

- (void)attachProxySocket: (SOCKSProxySocket*)socket;

@end
