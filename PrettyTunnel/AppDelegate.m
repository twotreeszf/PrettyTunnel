//
//  AppDelegate.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/5.
//
//

#import "AppDelegate.h"
#import "SOCKSProxy.h"
#import "BackgroundRunner/KPBackgroundRunner.h"

@interface AppDelegate ()
{
	SOCKSProxy*			_proxy;
	KPBackgroundRunner* _backgroundRunner;
}

- (void)_initApp;
- (void)_uninitApp;

@end

@implementation AppDelegate

+ (AppDelegate*)sharedInstance
{
	return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

- (SOCKSProxy*)socksProxy
{
	return _proxy;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	UIColor* globalColor = [UIColor colorWithRed:70.0/255 green:70.0/255.0 blue:70.0/255.0 alpha:1.0];
	[[UINavigationBar appearance] setBarTintColor:globalColor];
	[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
	[[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
	[[[[UIApplication sharedApplication] delegate] window ] setTintColor:globalColor];

	// [self _initApp];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	// [self _uninitApp];
}

- (void)_initApp
{
	[KPLog startup];
	
	_proxy = [SOCKSProxy new];
	[_proxy startProxyWithRemoteHost:@"www.kikjoy.com" RemotePort:22 UserName:@"fasttunnel" Password:@"bagemima" LocalPort:7070];
	
	_backgroundRunner = [KPBackgroundRunner new];
}

- (void)_uninitApp
{
	_backgroundRunner = nil;
	
	[_proxy disconnect];
	_proxy = nil;
}

@end
