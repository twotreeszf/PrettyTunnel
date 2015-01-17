//
//  UIView+UserData.h
//  PrettyTunnel
//
//  Created by zhang fan on 14-8-21.
//
//

#import <UIKit/UIKit.h>

@interface UIView (UserData)

@property (nonatomic, strong, readonly) NSMutableDictionary* userData;

- (UIView*)findSubviewByKey:(NSString*)key Value:(NSString*)value;

@end
