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
	[_proxy startProxyWithRemoteHost:@"www.kikjoy.com" RemotePort:22 UserName:@"fasttunnel" Password:@"bagemima" LocalPort:7070];
	
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
	
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
	
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	
}

@end
