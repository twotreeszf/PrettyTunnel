//
//  PacServer.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/2.
//
//

#import <Foundation/Foundation.h>

@interface PTPacServer : NSObject

@property(nonatomic, readonly) NSString*	pacFileAddress;
@property(nonatomic, readonly) BOOL			isRunning;

- (instancetype)initWithLocalProxyPort: (unsigned short)port;
- (BOOL)start;
- (BOOL)stop;

@end
