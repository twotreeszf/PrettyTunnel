//
//  PTPreference.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/8.
//
//

#import "PTPreference.h"

#define kDescription				@"description"
#define kRemoteServer				@"remoteServer"
#define kRemotePort					@"remotePort"
#define kUserName					@"userName"
#define kPassword					@"password"

@implementation PTPreference

+ (instancetype)sharedInstance
{
	static PTPreference* obj = nil;
	
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^
	{
	  obj = [[PTPreference alloc] init];
	});
	
	return obj;
}

+ (void)load
{
	NSDictionary* appDefaultsDic = @
	{
		kRemotePort  : [NSNumber numberWithUnsignedShort:22],
	};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaultsDic];

}

- (void)synchronize
{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)connectionDescription
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:kDescription];
}

- (void)setConnectionDescription: (NSString*)description
{
	[[NSUserDefaults standardUserDefaults] setObject:description forKey:kDescription];	
}

- (NSString*)remoteServer
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:kRemoteServer];
}

- (void)setRemoteServer: (NSString*)server
{
	[[NSUserDefaults standardUserDefaults] setObject:server forKey:kRemoteServer];
}

- (unsigned short)remotePort
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kRemotePort];
}

- (void)setRemotePort: (unsigned short)port
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedShort:port] forKey:kRemotePort];
}

- (NSString*)userName
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:kUserName];
}

- (void)setUserName: (NSString*)userName
{
	[[NSUserDefaults standardUserDefaults] setObject:userName forKey:kUserName];
}

- (NSString*)password
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:kPassword];
}

- (void)setPassword: (NSString*)password
{
	[[NSUserDefaults standardUserDefaults] setObject:password forKey:kPassword];
}

@end
