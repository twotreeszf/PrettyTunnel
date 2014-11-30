//
//  AppDelegate.h
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/5.
//
//

#import <UIKit/UIKit.h>

@class SOCKSProxy;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AppDelegate*)sharedInstance;
- (SOCKSProxy*)socksProxy;

@end

