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
	[self _initApp];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	[self _uninitApp];
}

- (void)_initApp
{
	self.window.backgroundColor = [UIColor whiteColor];
	UIPageControl *pageControl = [UIPageControl appearance];
	pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
	pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
	pageControl.backgroundColor = [UIColor whiteColor];
	
	[KPLog startup];
	
	_proxy = [SOCKSProxy new];
	_backgroundRunner = [KPBackgroundRunner new];
}

- (void)_uninitApp
{
	_backgroundRunner = nil;
	
	[_proxy disconnect];
	_proxy = nil;
}

@end
