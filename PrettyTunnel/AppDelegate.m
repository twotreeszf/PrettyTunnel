//
//  AppDelegate.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/5.
//
//

#import "AppDelegate.h"
#import "SOCKSProxy.h"

@interface AppDelegate ()
{
	SOCKSProxy* _proxy;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	_proxy = [SOCKSProxy new];
	[_proxy startProxyOnPort:7070];
	
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
	[_proxy startProxyOnPort:7070];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	[_proxy disconnect];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	
}

@end
