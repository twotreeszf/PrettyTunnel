//
//  AutoLocalize.h
//  AutoLocalize
//
//  Created by Stefan Matthias Aust on 05.08.11.
//  Copyright 2011 I.C.N.H. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (AutoLocalize)

/// Localize all strings settable by IB which start with %.
- (void)autoLocalize;

// Set keypath: autoLocalize = YES in storyboard User Defined Runtime Attribute
- (void)setAutoLocalize: (BOOL)b;

@end


@interface UIView (AutoLocalize)

/// Localize all strings settable by IB which start with %.
- (void)autoLocalize;

@end
