//
//  MainSettingsVC.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/4.
//
//

#import "PTMainSettingsVC.h"
#import "../Misc/UIView+UserData.h"
#import "../Preference/PTPreference.h"
#import "../SocksV5Proxy/SOCKSProxy.h"
#import "../AppDelegate.h"

@interface PTMainSettingsVC () <SOCKSProxyDelegate>
{
	NSArray* _sectionAndCells;
	
	__weak UILabel*		_connectionStateLabel;
	__weak UISwitch*	_connectionSwitch;
	__weak UILabel*		_connectionDescriptionLabel;
	
	__weak UILabel*		_pacFileURLLabel;
	__weak UILabel*		_connectedTimeLabel;
	__weak UILabel*		_totalSendLabel;
	__weak UILabel*		_totalRecvLabel;

	SOCKSProxy*			_proxy;
	NSDate*				_connectedTime;
}

- (void)_updateStatus;

@end

@implementation PTMainSettingsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self setAutoLocalize:YES];
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

	NSArray* configCellsID = @[ @"ConnectionStateCell", @"ConnectionConfigCell" ];
	NSArray* statusCellsID = @[ @"ProxyAddressCell", @"ConnectedTimeCell", @"TotalSendCell", @"TotalReceiveCell", @"RequestCountCell" ];
	_sectionAndCells = @[ configCellsID, statusCellsID ];
	
	_proxy = [[AppDelegate sharedInstance] socksProxy];
	_proxy.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self _updateStatus];
}

#pragma mark - User Action
- (IBAction)connectionSwitchChanged:(UISwitch*)sender
{
	if (sender.on)
	{
		_connectionStateLabel.text = LString(@"Connectting...");
		
		PTPreference* prefs = [PTPreference sharedInstance];
		[_proxy startProxyWithRemoteHost:prefs.remoteServer RemotePort:prefs.remotePort UserName:prefs.userName Password:prefs.password LocalPort:7777];
	}
	else
	{
		[_proxy disconnect];
		[self _updateStatus];
	}
}

- (IBAction)onCopyPACAddress:(id)sender
{
	[UIPasteboard generalPasteboard].string = _pacFileURLLabel.text;
}

#pragma mark - Status Delegate
- (void)sshLoginFailed: (int)error
{
	[self _updateStatus];
	_connectionStateLabel.text = LString(@"Connecte Failed");
	
	// todo: popup alert
}

- (void)sshLoginSuccessed
{
	_connectedTime = [NSDate date];
	
	[self _updateStatus];
}

- (void)sshSessionLost: (NSUInteger)index
{
	[_proxy disconnect];
	[self _updateStatus];
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
	
	if (!_connectionStateLabel)
		_connectionStateLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"ConnectionState"];
	
	if (!_connectionSwitch)
		_connectionSwitch = (UISwitch*)[cell findSubviewByKey:@"ID" Value:@"ConnectionSwitch"];
	
	if (!_connectionDescriptionLabel)
		_connectionDescriptionLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"ConnectionDescription"];
	
	if (!_pacFileURLLabel)
		_pacFileURLLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"PACFileURL"];
	
	if (!_connectedTimeLabel)
		_connectedTimeLabel	= (UILabel*)[cell findSubviewByKey:@"ID" Value:@"ConnectedTime"];
	
	if (!_totalSendLabel)
		_totalSendLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"TotalSend"];
	
	if (!_totalRecvLabel)
		_totalRecvLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"TotalRecv"];
	
    return cell;
}

#pragma mark - Private
- (void)_updateStatus
{
	PTPreference* prefs = [PTPreference sharedInstance];
	BOOL configValid = prefs.connectionDescription.length && prefs.remoteServer.length && prefs.remotePort && prefs.userName.length && prefs.password.length;
	_connectionDescriptionLabel.text = configValid ? prefs.connectionDescription : LString(@"Not Configured");
	
	if (_proxy.connected)
	{
		_connectionSwitch.enabled	= YES;
		_connectionSwitch.on		= YES;
		_connectionStateLabel.text	= LString(@"Connected");
		_pacFileURLLabel.text		= _proxy.pacFileAddress;
		
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_connectedTime];
		NSInteger hour		= (long)interval / kSeconds1Hour;
		NSInteger minute	= ((long)interval % kSeconds1Hour) / kSeconds1Min;
		NSInteger second	= (long)interval % kSeconds1Min;
		
		_connectedTimeLabel.text	= [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
		_totalSendLabel.text		= [NSString stringWithFormat:@"%f(MB)", (double)_proxy.totalBytesWritten / kMegaByte];
		_totalRecvLabel.text		= [NSString stringWithFormat:@"%f(MB)", (double)_proxy.totalBytesRead / kMegaByte];
	}
	else
	{
		_connectionSwitch.enabled	= configValid;
		_connectionSwitch.on		= NO;
		_connectionStateLabel.text	= LString(@"Not Connected");
		_pacFileURLLabel.text		= @"";
		_connectedTimeLabel.text	= @"00:00:00";
		_totalSendLabel.text		= @"0.0(MB)";
		_totalRecvLabel.text		= @"0.0(MB)";
	}
}

@end
