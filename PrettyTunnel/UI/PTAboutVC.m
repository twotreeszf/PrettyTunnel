//
//  PTAboutVC.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/17.
//
//

#import "PTAboutVC.h"

@interface PTAboutVC ()

@property (weak, nonatomic) IBOutlet UILabel* appVersion;

@end

@implementation PTAboutVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.autoLocalize = YES;
	
	NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString* build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	NSString* displayVersion = [NSString stringWithFormat:@"%@ build %@", version, build];
	self.appVersion.text = displayVersion;
}

- (IBAction)onTwitter:(id)sender
{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=twotreesx"]];
	else
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/TwoTreesX"]];
}

- (IBAction)onGithub:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/twotreeszf/PrettyTunnel"]];
}

@end
