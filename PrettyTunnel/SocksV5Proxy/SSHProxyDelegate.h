//
//  SSHProxyDelegate.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/18.
//
//

#ifndef PrettyTunnel_SSHProxyDelegate_h
#define PrettyTunnel_SSHProxyDelegate_h

@class SOCKSProxySocket;
@class SSHTCPDirectTunnel;
@protocol SOCKSProxySocketDelegate <NSObject>
@optional
- (void)proxySocket:(SOCKSProxySocket*)proxySocket didReadDataOfLength:(NSUInteger)numBytes;
- (void)proxySocket:(SOCKSProxySocket*)proxySocket didWriteDataOfLength:(NSUInteger)numBytes;

- (void)proxySocketDidDisconnect:(SOCKSProxySocket*)proxySocket withError:(NSError*)error;
- (void)sshSessionLost: (SSHTCPDirectTunnel*)sshProxy;
@end

#endif
