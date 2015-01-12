//
//  PTGuidePage.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/12.
//
//

#import "PTGuidePage.h"

@implementation PTGuidePage

- (void)viewDidLoad
{
	UIImage* guideImage = [UIImage imageNamed:[NSString stringWithFormat:@"Guide%u.png", self.index + 1]];
	self.guideImage.image = guideImage;
}

@end
