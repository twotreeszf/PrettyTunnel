//
//  SSHSession.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/6.
//
//

#import "SSHSession.h"
#include <sys/socket.h>
#include <arpa/inet.h>
#import "../../GCDAsyncSocket/GCDAsyncSocket.h"

@implementation SSHSession
{
	LIBSSH2_SESSION*	_session;
	int					_socket;
	BOOL				_conected;
}

- (instancetype)init
{
	self = [super init];
	
	_session = libssh2_session_init();
	
	return self;
}

- (void)dealloc
{
    [self disconnect];
}

- (int)connectToHost: (NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password
{
	X_ASSERT([host length]);
	X_ASSERT(port);
	X_ASSERT([username length]);
	X_ASSERT([password length]);
	
	int ret = LIBSSH2_ERROR_NONE;
	{
		_host		= host;
		_port		= port;
		_userName	= username;
		_password	= password;
		
		ret = [self reconnect];
		ERROR_CHECK_BOOL(LIBSSH2_ERROR_NONE == ret);
	}
Exit0:
	return ret;
}

- (int)reconnect
{
	int ret = LIBSSH2_ERROR_NONE;
	{
		NSArray* addrs = [GCDAsyncSocket lookupHost:_host port:_port error:nil];
		ERROR_CHECK_BOOLEX([addrs count], ret = LIBSSH2_ERROR_SOCKET_NONE);
		
		NSData* addr = addrs[0];
		_socket = socket(AF_INET, SOCK_STREAM, 0);
		ret = connect(_socket, (struct sockaddr*)(addr.bytes), addr.length);
		ERROR_CHECK_BOOLEX(!ret, ret = LIBSSH2_ERROR_SOCKET_NONE);

		ret = libssh2_session_handshake(_session, _socket);
		ERROR_CHECK_BOOL(LIBSSH2_ERROR_NONE == ret);
		
		ret = libssh2_userauth_password(_session, [_userName UTF8String], [_password UTF8String]);
		ERROR_CHECK_BOOL(LIBSSH2_ERROR_NONE == ret);
		
		libssh2_session_set_blocking(_session, 0);
	}
	
Exit0:
	return ret;
}

- (void)disconnect
{
	if (_conected)
		libssh2_session_disconnect(_session, "bye bye");

	if (_session)
	{
		libssh2_session_free(_session);
		_session = 0;
	}
	
	if (_socket)
	{
		close(_socket);
		_socket = 0;
	}
}

- (int)waitSession: (NSUInteger)timeoutSec;
{
	X_ASSERT(_session);
	X_ASSERT(_socket);
	
	struct timeval timeout;
	timeout.tv_sec = 10;
	timeout.tv_usec = 0;

	fd_set fd;
	FD_ZERO(&fd);
	FD_SET(_socket, &fd);
	
	/* now make sure we wait in the correct direction */
	int dir = libssh2_session_block_directions(_session);
	
	fd_set* writefd;
	fd_set* readfd;
	if (dir & LIBSSH2_SESSION_BLOCK_INBOUND)
		readfd = &fd;
	
	if (dir & LIBSSH2_SESSION_BLOCK_OUTBOUND)
		writefd = &fd;
	
	int ret = select(_socket + 1, readfd, writefd, NULL, &timeout);
	return ret;
}

- (SSHChannel*)channelDirectTCPIPWithSourceHost:(NSString*)sourceHost SourcePort:(UInt16)sourcePort DestHost:(NSString*)destHost DestPort:(UInt16)destPort
{
	X_ASSERT([sourceHost length]);
	X_ASSERT(sourcePort);
	X_ASSERT([destHost length]);
	X_ASSERT(destPort);
	
	SSHChannel* channel;
	{
		LIBSSH2_CHANNEL* channel_;
		while ((channel_ = libssh2_channel_open_session(_session)) == NULL &&
			   libssh2_session_last_error(_session, NULL, NULL, 0) == LIBSSH2_ERROR_EAGAIN)
		{
			[self waitSession:1];
		}
		ERROR_CHECK_BOOL(channel_);
		
		channel = [[SSHChannel alloc] initWithSession:self Channel:channel_];
	}
	
Exit0:
	return channel;
}

@end
