//
//  TTSystemProxyManager.h
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/15.
//
//

#import <Foundation/Foundation.h>

@interface TTSystemProxyManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)enableSocksProxy: (NSString*)host :(int)port;
- (BOOL)enablePACProxy: (NSString*)pacURL;
- (BOOL)disableProxy;

@end
