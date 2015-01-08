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
#import "../Misc/MBProgressHUD/MBProgressHUD.h"

typedef NS_ENUM(NSUInteger, PTConnectStatus)
{
	PTCS_Disconnected = 0,
	PTCS_Waitting,
	PTCS_Connected,
	PTCS_Failed
};

@interface PTMainSettingsVC () <UITableViewDelegate, UITableViewDataSource, SOCKSProxyDelegate>
{
	NSArray* _sectionAndCells;
	
	__weak UILabel*		_connectionStateLabel;
	__weak UISwitch*	_connectionSwitch;
	__weak UILabel*		_connectionDescriptionLabel;
	
	__weak UILabel*		_pacFileURLLabel;
	__weak UILabel*		_dnsAddressLabel;
	__weak UILabel*		_connectedTimeLabel;
	__weak UILabel*		_totalSendLabel;
	__weak UILabel*		_totalRecvLabel;
	__weak UILabel*		_requestCountLabel;

	SOCKSProxy*			_proxy;
	PTConnectStatus		_status;
	NSDate*				_connectedTime;
	NSTimer*			_timer;
	MBProgressHUD*		_loadingHUD;
	MBProgressHUD*		_messageHUD;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)_updateStatus;
- (void)_onTimer;
- (void)_startTimer;
- (void)_stopTimer;
- (void)_onApplicationDidEnterBackground: (NSNotification*)notification;
- (void)_onApplicationWillEnterForeground: (NSNotification*)notification;

@end

@implementation PTMainSettingsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self setAutoLocalize:YES];
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;

	NSArray* configCellsID = @[ @"ConnectionStateCell", @"ConnectionConfigCell" ];
	NSArray* statusCellsID = @[ @"ProxyAddressCell", @"DNSAddressCell", @"ConnectedTimeCell", @"TotalSendCell", @"TotalReceiveCell", @"RequestCountCell" ];
	_sectionAndCells = @[ configCellsID, statusCellsID ];
	
	_proxy = [[AppDelegate sharedInstance] socksProxy];
	_proxy.delegate = self;
	_status = PTCS_Disconnected;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_onApplicationDidEnterBackground:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_onApplicationWillEnterForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
		_status = PTCS_Waitting;
		[self _updateStatus];
		
		PTPreference* prefs = [PTPreference sharedInstance];
		[_proxy startProxyWithRemoteHost:prefs.remoteServer RemotePort:prefs.remotePort UserName:prefs.userName Password:prefs.password LocalPort:7777];
		
		_loadingHUD = [MBProgressHUD initHUBAddedTo:nil withTitle:NSLocalizedString(@"Connectting...", nil) withMode:MBProgressHUDModeIndeterminate];
		[_loadingHUD show:YES];
	}
	else
	{
		[_proxy disconnect];
		
		_status = PTCS_Disconnected;
		[self _updateStatus];
	}
}

- (IBAction)onCopyPACAddress:(id)sender
{
	if (_pacFileURLLabel.text.length)
	{
		[UIPasteboard generalPasteboard].string = _pacFileURLLabel.text;
		
		_messageHUD = [MBProgressHUD initHUBAddedTo:nil withTitle:NSLocalizedString(@"Copied", nil) withMode:MBProgressHUDModeText];
		[_messageHUD show:YES];
		[_messageHUD hide:YES afterDelay:0.5];
	}
}

- (IBAction)onCopyDNSAddress:(id)sender
{
	if (_dnsAddressLabel.text.length)
	{
		[UIPasteboard generalPasteboard].string = _dnsAddressLabel.text;
		
		_messageHUD = [MBProgressHUD initHUBAddedTo:nil withTitle:NSLocalizedString(@"Copied", nil) withMode:MBProgressHUDModeText];
		[_messageHUD show:YES];
		[_messageHUD hide:YES afterDelay:0.5];
	}
}

#pragma mark - Status Delegate
- (void)sshLoginFailed: (int)error
{
	[_loadingHUD hide:YES];
	
	NSString* message;
	if (LIBSSH2_ERROR_AUTHENTICATION_FAILED == error)
		message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Connecte Failed", nil), NSLocalizedString(@"User name and password not match", nil)];
	else
		message = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Connecte Failed", nil), NSLocalizedString(@"Can not connect to server", nil)];
		
	_messageHUD = [MBProgressHUD initHUBAddedTo:nil withTitle:message withMode:MBProgressHUDModeText];
	[_messageHUD show:YES];
	[_messageHUD hide:YES afterDelay:3.0];
	
	_status = PTCS_Failed;
	[self _updateStatus];
}

- (void)sshLoginSuccessed
{
	[_loadingHUD hide:YES];
	
	_messageHUD = [MBProgressHUD initHUBAddedTo:nil withTitle:NSLocalizedString(@"Connect Success", nil) withMode:MBProgressHUDModeText];
	[_messageHUD show:YES];
	[_messageHUD hide:YES afterDelay:1.0];
	
	_connectedTime = [NSDate date];
	_status = PTCS_Connected;
	
	[self _updateStatus];
	[self _startTimer];
}

- (void)sshSessionLost: (NSUInteger)index
{
	[_proxy disconnect];
	
	_status = PTCS_Disconnected;
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
	{
		_connectionDescriptionLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"ConnectionDescription"];
		if (_connectionDescriptionLabel)
			[self _updateStatus];
	}
	
	if (!_pacFileURLLabel)
		_pacFileURLLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"PACFileURL"];
	
	if (!_dnsAddressLabel)
		_dnsAddressLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"DNSAddr"];
	
	if (!_connectedTimeLabel)
		_connectedTimeLabel	= (UILabel*)[cell findSubviewByKey:@"ID" Value:@"ConnectedTime"];
	
	if (!_totalSendLabel)
		_totalSendLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"TotalSend"];
	
	if (!_totalRecvLabel)
		_totalRecvLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"TotalRecv"];
	
	if (!_requestCountLabel)
		_requestCountLabel = (UILabel*)[cell findSubviewByKey:@"ID" Value:@"RequestCount"];
	
    return cell;
}

#pragma mark - Private
- (void)_updateStatus
{
	PTPreference* prefs = [PTPreference sharedInstance];
	BOOL configValid = prefs.connectionDescription.length && prefs.remoteServer.length && prefs.remotePort && prefs.userName.length && prefs.password.length;
	_connectionDescriptionLabel.text = configValid ? prefs.connectionDescription : LString(@"Not Configured");
	
	switch (_status)
	{
		case PTCS_Disconnected:
			_connectionSwitch.enabled	= configValid;
			_connectionSwitch.on		= NO;
			_connectionStateLabel.text	= LString(@"Not Connected");
			_pacFileURLLabel.text		= @"";
			_dnsAddressLabel.text		= @"";
			_connectedTimeLabel.text	= @"00:00:00";
			_totalSendLabel.text		= @"0.0(MB)";
			_totalRecvLabel.text		= @"0.0(MB)";
			_requestCountLabel.text		= @"0";
			break;
			
		case PTCS_Waitting:
			_connectionStateLabel.text = LString(@"Connectting...");
			_connectionSwitch.enabled = NO;
			break;
			
		case PTCS_Failed:
			_connectionSwitch.on		= NO;
			_connectionSwitch.enabled	= YES;
			_connectionStateLabel.text = LString(@"Connecte Failed");
			break;

		case PTCS_Connected:
			_connectionSwitch.enabled	= YES;
			_connectionSwitch.on		= YES;
			_connectionStateLabel.text	= LString(@"Connected");
			_pacFileURLLabel.text		= _proxy.pacFileAddress;
			_dnsAddressLabel.text		= _proxy.dnsAddress;
			
			NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_connectedTime];
			NSInteger hour		= (long)interval / kSeconds1Hour;
			NSInteger minute	= ((long)interval % kSeconds1Hour) / kSeconds1Min;
			NSInteger second	= (long)interval % kSeconds1Min;
			
			_connectedTimeLabel.text	= [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
			_totalSendLabel.text		= [NSString stringWithFormat:@"%.01f(MB)", (double)_proxy.totalBytesWritten / kMegaByte];
			_totalRecvLabel.text		= [NSString stringWithFormat:@"%.01f(MB)", (double)_proxy.totalBytesRead / kMegaByte];
			_requestCountLabel.text		= [NSString stringWithFormat:@"%d", _proxy.connectionCount];
			break;
  default:
			break;
	}
}

- (void)_onTimer
{
	[self _updateStatus];
	
	if (_status != PTCS_Connected)
		[self _stopTimer];
}

- (void)_startTimer
{
	_timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_onTimer) userInfo:nil repeats:YES];
}

- (void)_stopTimer
{
	[_timer invalidate];
	_timer = nil;
}

- (void)_onApplicationDidEnterBackground: (NSNotification*)notification
{
	if (PTCS_Connected == _status)
		[self _stopTimer];
}

- (void)_onApplicationWillEnterForeground: (NSNotification*)notification
{
	if (PTCS_Connected == _status)
		[self _startTimer];
}

@end
