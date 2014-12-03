//
//  PacServer.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/12/2.
//
//

#import "PacServer.h"
#import "../../GCDWebServer/Core/GCDWebServer.h"
#import "../../GCDWebServer/Core/GCDWebServerConnection.h"
#import "../../GCDWebServer/Responses/GCDWebServerDataResponse.h"
#import "../../GCDWebServer/Requests/GCDWebServerDataRequest.h"

#define kRootPath						@"/"
#define kPacFilePath					@"global.pac"
#define kGlobalPacFile					@"\
function FindProxyForURL(url, host)\
{\
	var direct = 'DIRECT';\
	var tunnel = 'SOCKS 127.0.0.1:%@';\
	\
	if (isPlainHostName(host)              ||\
		host.indexOf('127.') == 0          ||\
		host.indexOf('192.168.') == 0      ||\
		host.indexOf('10.') == 0           ||\
		shExpMatch(host, 'localhost.*'))\
	{\
		return direct;\
	}\
	else\
	{\
		return tunnel;\
	}\
}"

@interface PacServer()
{
	unsigned short	_proxyPort;
	GCDWebServer*	_webServer;
}
@end

@implementation PacServer

- (instancetype)initWithLocalProxyPort: (unsigned short)port
{
	self = [super init];
	
	_proxyPort = port;
	_webServer = [GCDWebServer new];
	
	__weak PacServer* weakSelf = self;
	[_webServer addHandlerForMethod:@"GET" path:kRootPath kPacFilePath requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request)
	{
		return [weakSelf globalPac:request];
	}];
	
	return self;
}

- (BOOL)start
{
	BOOL ret = YES;
	{
		NSArray* defaultPorts = @[@80, @88, @8888, @8080];
		for (NSNumber* port in defaultPorts)
		{
			NSMutableDictionary* options = [NSMutableDictionary dictionary];
			[options setObject:port forKey:GCDWebServerOption_Port];
			[options setObject:@YES forKey:GCDWebServerOption_BindToLocalhost];
			[options setObject:@NO	forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
			[options setObject:NSStringFromClass([self class]) forKey:GCDWebServerOption_ServerName];

			ret = [_webServer startWithOptions:options error:nil];
			if (ret)
				break;
		}
		if (!ret)
			ret = [_webServer startWithPort:0 bonjourName:nil];
		ERROR_CHECK_BOOL(ret);
	}
	
Exit0:
	return ret;
}

- (BOOL)stop
{
	[_webServer stop];
	return YES;
}

- (NSString*)pacFileAddress
{
	NSString* pacFileURL = [[_webServer.serverURL URLByAppendingPathComponent:kPacFilePath] absoluteString];
	return pacFileURL;
}

- (GCDWebServerResponse*)globalPac :(GCDWebServerRequest*)request
{
	NSString* pacFile = [NSString stringWithFormat:kGlobalPacFile, [NSNumber numberWithUnsignedShort:_proxyPort]];
	
	return [[GCDWebServerDataResponse alloc] initWithText:pacFile];
}

@end
