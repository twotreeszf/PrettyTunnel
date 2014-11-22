//
//  SSHChannel.m
//  PrettyTunnel
//
//  Created by zhang fan on 14/11/6.
//
//

#import "SSHChannel.h"
#import "SSHSession.h"

#define kChannelReadBufferLen (16 * 1024)

@implementation SSHChannel
{
	__weak SSHSession*	_session;
	LIBSSH2_CHANNEL*	_channel;
}

- (instancetype)initWithSession:(SSHSession*)session Channel:(LIBSSH2_CHANNEL*)channel
{
	X_ASSERT(session);
	X_ASSERT(channel);
	
	self = [super init];
	
	_session = session;
	_channel = channel;
	
	return self;
}

- (void)dealloc
{
    if (_channel)
        [self close];
}

- (NSData*)read:(int*)error
{
    NSMutableData* data = [NSMutableData dataWithLength:kChannelReadBufferLen];

    int len = (int)libssh2_channel_read(_channel, data.mutableBytes, data.length);
	*error = len;
	
    if (len > 0)
	{
		[data setLength:len];
		return data;
	}
	else
		return nil;
}

- (int)write:(NSData*)data :(int*)error
{
    int leftLen = (int)data.length;
    const char* buffer = (const char*)data.bytes;

    while (leftLen)
    {
        int sendLen = (int)libssh2_channel_write(_channel, buffer, leftLen);
		*error = sendLen;
		
        if (sendLen > 0)
        {
            leftLen		-= sendLen;
            buffer		+= sendLen;
        }
        else
            break;
    }

    return data.length - leftLen;
}

- (BOOL)isEOF
{
    return libssh2_channel_eof(_channel);
}

- (int)close
{
	int ret = 0;
	BOOL retry;
	while (retry)
	{
		ret = libssh2_channel_close(_channel);
		retry = (LIBSSH2_ERROR_EAGAIN == ret);
		if (retry)
			usleep(10 * 1000);
	}
	
	libssh2_channel_free(_channel);
	_channel = 0;
	
	return ret;
}

@end
