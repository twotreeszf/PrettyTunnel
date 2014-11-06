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

- (void)close;
- (int)waitSession;
- (int)read:(NSData* __autoreleasing *)data;
- (int)write:(NSData*)data;

- (BOOL)isEOF;

@end
