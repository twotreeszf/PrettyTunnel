//
//  AutoLocalize.m
//  AutoLocalize
//
//  Created by Stefan Matthias Aust on 05.08.11.
//  Copyright 2011 I.C.N.H. All rights reserved.
//

#import "AutoLocalize.h"

/// Like NSLocalizedString macro, but returning the key unchanged if no value is found.
static NSString *L(NSString *key) {
    return [[NSBundle mainBundle] localizedStringForKey:key value:key table:nil];
}

/// Localize string
static NSString *AutoLocalize(NSString *string) {
    if (string.length)
        string = L(string);
	
    return string;
}

@implementation UIViewController (AutoLocalize)

/// Localize the controller's view, the optional navigation item and all tab bar items.
- (void)autoLocalize {
    // need to translate all items or all view controllers now
    UITabBarController *tabBarController = self.tabBarController;
    if (tabBarController) {
        for (UIViewController *viewController in tabBarController.viewControllers) {
            UITabBarItem *tabBarItem = viewController.tabBarItem;
            if (tabBarItem) {
                tabBarItem.title = AutoLocalize(tabBarItem.title);
            }
        }
    }
    
    UINavigationItem *navigationItem = self.navigationItem;
    if (navigationItem) {
        navigationItem.title = AutoLocalize(navigationItem.title);
        navigationItem.prompt = AutoLocalize(navigationItem.prompt);
        navigationItem.leftBarButtonItem.title = AutoLocalize(navigationItem.leftBarButtonItem.title);
        navigationItem.rightBarButtonItem.title = AutoLocalize(navigationItem.rightBarButtonItem.title);
        navigationItem.backBarButtonItem.title = AutoLocalize(navigationItem.backBarButtonItem.title);
    }

    [self.view autoLocalize];
}

- (void)setAutoLocalize: (BOOL)b
{
	if (b)
		[self autoLocalize];
}

@end

@implementation UIView (AutoLocalize)

/// Localize this view and all subviews. For generic views, accessibility stuff is translated.
- (void)autoLocalize {
    for (UIView *view in self.subviews) {
        [view autoLocalize];
    }
    if (self.isAccessibilityElement) {
        self.accessibilityHint = AutoLocalize(self.accessibilityHint);
        self.accessibilityLabel = AutoLocalize(self.accessibilityLabel);
    }
}

@end

@implementation UILabel (AutoLocalize)

/// Localize the label's text.
- (void)autoLocalize {
    [super autoLocalize];
    self.text = AutoLocalize(self.text);
}

@end

@implementation UIButton (AutoLocalize)

/// Localize the button's four state labels.
- (void)autoLocalize {
    [super autoLocalize];
    [self setTitle:AutoLocalize([self titleForState:UIControlStateNormal]) forState:UIControlStateNormal];
    [self setTitle:AutoLocalize([self titleForState:UIControlStateHighlighted]) forState:UIControlStateHighlighted];
    [self setTitle:AutoLocalize([self titleForState:UIControlStateSelected]) forState:UIControlStateSelected];
    [self setTitle:AutoLocalize([self titleForState:UIControlStateDisabled]) forState:UIControlStateDisabled];
}

@end

@implementation UISegmentedControl (AutoLocalize)

/// Localize the segmented control's title.
- (void)autoLocalize {
    [super autoLocalize];
    for (NSUInteger index = 0; index < self.numberOfSegments; index++) {
        [self setTitle:AutoLocalize([self titleForSegmentAtIndex:index]) forSegmentAtIndex:index];
    }
}

@end

@implementation UITextField (AutoLocalize)

/// Localize the text field's text and placeholder.
- (void)autoLocalize {
    [super autoLocalize];
    self.text = AutoLocalize(self.text);
    self.placeholder = AutoLocalize(self.placeholder);
}

@end

@implementation UITextView (AutoLocalize)

/// Localize the text view's text.
- (void)autoLocalize {
    [super autoLocalize];
    self.text = AutoLocalize(self.text);
}

@end

@implementation UISearchBar (AutoLocalize)

/// Localize text search field's text, placeholder, prompt and scope titles.
- (void)autoLocalize {
    [super autoLocalize];
    self.text = AutoLocalize(self.text);
    self.placeholder = AutoLocalize(self.placeholder);
    self.prompt = AutoLocalize(self.prompt);
    NSArray *scopeButtonTitles = self.scopeButtonTitles;
    if ([scopeButtonTitles count]) {
        NSMutableArray *translatedScopeButtonTitles = [NSMutableArray arrayWithCapacity:[scopeButtonTitles count]];
        for (NSString *title in scopeButtonTitles) {
            [translatedScopeButtonTitles addObject:AutoLocalize(title)];
        }
        self.scopeButtonTitles = translatedScopeButtonTitles;
    }
}

@end

@implementation UIToolbar (AutoLocalize)

/// Localize the toolbar's items.
- (void)autoLocalize {
    for (UIBarButtonItem *item in self.items) {
        item.title = AutoLocalize(item.title);
    }
}

@end
