//
//  PTConnectionSettings.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/8.
//
//

#import "PTConnectionSettings.h"
#import "PTPreference.h"

@interface PTConnectionSettings ()

@property (weak, nonatomic) IBOutlet UITextField *connectionName;
@property (weak, nonatomic) IBOutlet UITextField *serverAddress;
@property (weak, nonatomic) IBOutlet UITextField *serverPort;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *save;

- (BOOL)_verifyInput;

@end

@implementation PTConnectionSettings

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self autoLocalize];
	
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	
	PTPreference* prefs = [PTPreference sharedInstance];
	self.connectionName.text	= prefs.connectionDescription;
	self.serverAddress.text		= prefs.remoteServer;
	self.serverPort.text		= [NSString stringWithFormat:@"%u", prefs.remotePort];
	self.userName.text			= prefs.userName;
	self.password.text			= prefs.password;
	
	self.save.enabled = [self _verifyInput];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell autoLocalize];
}

- (IBAction)onSave:(id)sender
{
	PTPreference* prefs = [PTPreference sharedInstance];

	prefs.connectionDescription = self.connectionName.text;
	prefs.remoteServer			= self.serverAddress.text;
	prefs.remotePort			= self.serverPort.text.intValue;
	prefs.userName				= self.userName.text;
	prefs.password				= self.password.text;

	[prefs synchronize];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onInputChanged:(id)sender
{
	self.save.enabled = [self _verifyInput];
}

- (BOOL)_verifyInput
{
	return
	self.connectionName.text.length &&
	self.serverAddress.text.length &&
	self.serverPort.text.length &&
	self.userName.text.length &&
	self.password.text.length;
}

@end
