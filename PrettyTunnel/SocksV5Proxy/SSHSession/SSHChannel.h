//
//  SSHChannel.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/6.
//
//

#import <Foundation/Foundation.h>
#import <libssh2/libssh2.h>

@class SSHSession;
@interface SSHChannel : NSObject

- (instancetype)initWithSession:(SSHSession*)session Channel:(LIBSSH2_CHANNEL*)channel;
- (void)dealloc;

- (NSData*)read:(int*)error;
- (int)write:(NSData*)data :(int*)error;

- (BOOL)isEOF;
- (int)close;

@end
