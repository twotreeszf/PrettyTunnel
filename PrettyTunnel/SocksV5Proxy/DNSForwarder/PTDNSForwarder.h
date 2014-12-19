//
//  PTDNSForwarder.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/19.
//
//

#import <Foundation/Foundation.h>

@interface PTDNSForwarder : NSObject

@property (nonatomic, readonly) NSString* localDNSAddr;

- (void)startWithSocketAddr: (NSString*)addr Port:(int)port;
- (void)stop;

@end
