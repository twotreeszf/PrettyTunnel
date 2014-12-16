//
//  PTPreference.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/8.
//
//

#import <Foundation/Foundation.h>

@interface PTPreference : NSObject

+  (instancetype)sharedInstance;

- (void)synchronize;

- (NSString*)connectionDescription;
- (void)setConnectionDescription: (NSString*)description;

- (NSString*)remoteServer;
- (void)setRemoteServer: (NSString*)server;

- (unsigned short)remotePort;
- (void)setRemotePort: (unsigned short)port;

- (NSString*)userName;
- (void)setUserName: (NSString*)userName;

- (NSString*)password;
- (void)setPassword: (NSString*)password;

@end
