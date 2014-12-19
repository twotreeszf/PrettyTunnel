//
//  PTDNSForwarder.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/19.
//
//

#import "PTDNSForwarder.h"
#import "ttdnsd.h"

@implementation PTDNSForwarder

- (NSString*)localDNSAddr
{
	return @"127.0.0.1";
}

- (void)startWithSocketAddr: (NSString*)addr Port:(int)port
{
	DNSServer::getInstance()->startDNSServer("127.0.0.1", "8.8.8.8", 53, 53, 3, 1, [addr UTF8String], port);
}

- (void)stop
{
	DNSServer::getInstance()->stopDNSServer();
}

@end
