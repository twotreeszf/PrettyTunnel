//
//  PTConnectionSettings.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/8.
//
//

#import "PTConnectionSettings.h"

@interface PTConnectionSettings ()

@end

@implementation PTConnectionSettings

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self autoLocalize];
	
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell autoLocalize];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
