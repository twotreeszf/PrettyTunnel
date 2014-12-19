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

+ (BOOL)isSocketError:(int)error
{
    BOOL ret;

    switch (error)
    {
    case LIBSSH2_ERROR_SOCKET_NONE:
    case LIBSSH2_ERROR_SOCKET_DISCONNECT:
	case LIBSSH2_ERROR_SOCKET_RECV:
	case LIBSSH2_ERROR_SOCKET_SEND:
	case LIBSSH2_ERROR_SOCKET_TIMEOUT:
			ret = YES;
		break;

    default:
			ret = NO;
        break;
    }

    return ret;
}

+ (BOOL)isChannelError:(int)error
{
	BOOL ret;
	
	switch (error)
	{
		case LIBSSH2_ERROR_CHANNEL_CLOSED:
		case LIBSSH2_ERROR_CHANNEL_EOF_SENT:
		case LIBSSH2_ERROR_CHANNEL_FAILURE:
		case LIBSSH2_ERROR_CHANNEL_OUTOFORDER:
		case LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED:
		case LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED:
		case LIBSSH2_ERROR_CHANNEL_UNKNOWN:
		case LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED:
			ret = YES;
			break;
			
		default:
			ret = NO;
			break;
	}
	
	return ret;
}

- (int)connectToHost:(NSString*)host Port:(UInt16)port Username:(NSString*)username Password:(NSString*)password
{
    X_ASSERT([host length]);
    X_ASSERT(port);
    X_ASSERT([username length]);
    X_ASSERT([password length]);

    int ret = LIBSSH2_ERROR_NONE;
    {
        _host = host;
        _port = port;
        _userName = username;
        _password = password;

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

        _conected = YES;
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

    _conected = NO;
}

- (BOOL)isConnected
{
	return _conected;
}

- (SSHSessionStatus)waitSession:(SSHSessionStatus)waitStatus :(NSUInteger)timeoutMillisec;
{
	X_ASSERT(_session);
	X_ASSERT(_socket);
	
	struct timeval timeout;
	timeout.tv_sec = 0;
	timeout.tv_usec = timeoutMillisec * 1000;

	fd_set fdRead;
	FD_ZERO(&fdRead);
	FD_SET(_socket, &fdRead);
	
	fd_set fdWrite;
	FD_ZERO(&fdWrite);
	FD_SET(_socket, &fdWrite);
	
	fd_set fdExcept;
	FD_ZERO(&fdExcept);
	FD_SET(_socket, &fdExcept);
	
	fd_set* readSet = (waitStatus & SSHSS_Read) ? &fdRead : NULL;
	fd_set* writeSet = (waitStatus & SSHSS_Write) ? &fdWrite : NULL;
	fd_set* exceptSet = (waitStatus & SSHSS_Except) ? &fdExcept : NULL;
	
	int ret = select(_socket + 1, readSet, writeSet, exceptSet, &timeout);
	if (ret > 0)
	{
		SSHSessionStatus status = SSHSS_None;
		if (FD_ISSET(_socket, &fdRead))
			status |= SSHSS_Read;
		if (FD_ISSET(_socket, &fdWrite))
			status |= SSHSS_Write;
		if (FD_ISSET(_socket, &fdExcept))
			status |= SSHSS_Except;
		
		return status;
	}
	else if (!ret)
		return SSHSS_None;
	else if (-1 == ret)
		return SSHSS_Except;
	else
	{
		X_ASSERT(false);
		return SSHSS_None;
	}
}

- (int)lastError
{
	return libssh2_session_last_error(_session, NULL, NULL, 0);
}

- (SSHChannel*)channelDirectTCPIPWithDestHost:(NSString*)destHost DestPort:(UInt16)destPort;
{
    X_ASSERT([destHost length]);
    X_ASSERT(destPort);

    SSHChannel* channel;
    {
		LIBSSH2_CHANNEL* channel_ = libssh2_channel_direct_tcpip(_session, [destHost UTF8String], destPort);
		ERROR_CHECK_BOOL(channel_);
		channel = [[SSHChannel alloc] initWithSession:self Channel:channel_];
    }

Exit0:
    return channel;
}

@end
