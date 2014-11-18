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
	__weak SSHSession*			_session;
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

- (void)close
{
	while (true)
	{
		int ret = libssh2_channel_close(_channel);
		if (LIBSSH2_ERROR_EAGAIN == ret)
			[_session waitSessionWrite:1];
		else
			break;
	}

	libssh2_channel_free(_channel);
	_channel = 0;
}

- (int)read:(NSData* __autoreleasing*)data
{
    NSMutableData* data_ = [NSMutableData dataWithLength:kChannelReadBufferLen];

    int len = (int)libssh2_channel_read(_channel, data_.mutableBytes, data_.length);
    if (len > 0)
    {
        [data_ setLength:len];
        *data = data_;
    }

    return len;
}

- (int)write:(NSData*)data
{
    int sendLen;
    int leftLen = (int)data.length;
    const char* buffer = (const char*)data.bytes;

    while (leftLen)
    {
        int sendLen;
        while (true)
        {
            sendLen = (int)libssh2_channel_write(_channel, buffer, leftLen);

            if (LIBSSH2_ERROR_EAGAIN == sendLen)
                [self waitSession];
            else
                break;
        }

        if (sendLen >= 0)
        {
            leftLen -= sendLen;
            buffer += sendLen;
        }
        else
            break;
    }

    return sendLen;
}

- (BOOL)isEOF
{
    return libssh2_channel_eof(_channel);
}

@end
