//
//  UIView+UserData.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-8-21.
//
//

#import "UIView+UserData.h"
#import <objc/runtime.h>

@implementation UIView (UserData)

static NSString const * kUserDataKey = @"KPUserDataKey";

- (NSMutableDictionary*)userData
{
	NSMutableDictionary* dic =  (NSMutableDictionary*)objc_getAssociatedObject(self, CFBridgingRetain(kUserDataKey));
	if (!dic)
	{
		dic = [NSMutableDictionary new];
		
		objc_setAssociatedObject(self, CFBridgingRetain(kUserDataKey), dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return dic;
}

- (UIView*)findSubviewByKey:(NSString*)key Value:(NSString*)value;
{
	X_ASSERT([key length]);
	X_ASSERT([value length]);
	
	UIView* view;
	
	NSMutableArray* queue = [NSMutableArray new];
	[queue enqueue:self];
	
	while ([queue count])
	{
		// find current view
		UIView* currentView = [queue dequeue];
		NSMutableDictionary* userData =  (NSMutableDictionary*)objc_getAssociatedObject(currentView, CFBridgingRetain(kUserDataKey));
		if (userData && [[userData valueForKey:key] isEqualToString:value])
		{
			view = currentView;
			break;
		}

		// enqueue subview
		for (UIView* subView in currentView.subviews)
		{
			[queue enqueue:subView];
		}
	}
	
	return view;
}

@end
