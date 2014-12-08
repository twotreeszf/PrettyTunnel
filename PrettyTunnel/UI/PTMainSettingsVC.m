//
//  MainSettingsVC.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/4.
//
//

#import "PTMainSettingsVC.h"

@interface PTMainSettingsVC ()
{
	NSArray* _sectionAndCells;
}

@end

@implementation PTMainSettingsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setAutoLocalize:YES];
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

	NSArray* configCellsID = @[@"ConnectionStateCell", @"ConnectionConfigCell"];
	NSArray* statusCellsID = @[ @"ProxyAddressCell", @"ConnectedTimeCell", @"TotalSendCell", @"TotalReceiveCell", @"RequestCountCell"];
	_sectionAndCells = @[ configCellsID, statusCellsID ];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return _sectionAndCells.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_sectionAndCells[section] count];
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
	UILabel* lable = [UILabel new];
	lable.font = [UIFont systemFontOfSize:12.0];
	lable.textColor = [UIColor whiteColor];
	lable.backgroundColor = [UIColor lightGrayColor];

	if (0 == section)
		lable.text = [@" " stringByAppendingString: NSLocalizedString(@"CONNECTION CONFIG", nil)];
	else
		lable.text = [@" " stringByAppendingString: NSLocalizedString(@"CONNECTION STATE", nil)];
	
	return lable;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:_sectionAndCells[indexPath.section][indexPath.row] forIndexPath:indexPath];
	[cell autoLocalize];
	
    return cell;
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
