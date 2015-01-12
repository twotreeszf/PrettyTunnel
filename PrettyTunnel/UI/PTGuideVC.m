//
//  PTGuideVC.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/12.
//
//

#import "PTGuideVC.h"
#import "PTGuidePage.h"

#define kPageCount					8

@interface PTGuideVC () <UIPageViewControllerDataSource>

- (UIViewController*)_pageAtIndex:(NSUInteger)index;

@end

@implementation PTGuideVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setAutoLocalize:YES];

	self.dataSource = self;
	
	[self setViewControllers:@[[self _pageAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
	NSUInteger index = ((PTGuidePage*)viewController).index;
	if (0 == index)
		return nil;
	else
		return [self _pageAtIndex:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
	NSUInteger index = ((PTGuidePage*)viewController).index;
	if ((kPageCount - 1) == index)
		return nil;
	else
		return [self _pageAtIndex:index + 1];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
	return kPageCount;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
	return 0;
}

- (UIViewController*)_pageAtIndex:(NSUInteger)index
{
	PTGuidePage* page = (PTGuidePage*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"GuidePage"];
	page.index = index;
	
	return page;
}

@end
