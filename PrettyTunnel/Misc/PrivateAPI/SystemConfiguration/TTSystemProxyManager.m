//
//  TTSystemProxyManager.m
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/15.
//
//

#import "TTSystemProxyManager.h"
#import "PrivateSystemConfiguration.h"

@interface TTSystemProxyManager ()

- (CFMutableDictionaryRef)_getSocksConfigDic:(NSString*)host :(int)port;
- (CFMutableDictionaryRef)_getPACConfigDic:(NSString*)pacURL;
- (CFMutableDictionaryRef)_getEmptyConfigDic;
- (BOOL)_setProxyDic: (CFMutableDictionaryRef)proxyDic;

@end

@implementation TTSystemProxyManager

+ (instancetype)sharedInstance
{
    static TTSystemProxyManager* obj;
    static dispatch_once_t token;

    dispatch_once(&token, ^{
	  obj = [TTSystemProxyManager new];
    });

    return obj;
}

- (BOOL)enableSocksProxy:(NSString*)host :(int)port
{
	BOOL ret = YES;
	{
		TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];
		
		CFMutableDictionaryRef dic = [self _getSocksConfigDic:host :port];
		[pool autorelease:dic];
		
		ret = [self _setProxyDic:dic];
		ERROR_CHECK_BOOL(ret);
	}
	
Exit0:
	return ret;
}

- (BOOL)enablePACProxy:(NSString*)pacURL
{
	BOOL ret = YES;
	{
		TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];
		
		CFMutableDictionaryRef dic = [self _getPACConfigDic:pacURL];
		[pool autorelease:dic];
		
		ret = [self _setProxyDic:dic];
		ERROR_CHECK_BOOL(ret);
	}
	
Exit0:
	return ret;
}

- (BOOL)disableProxy
{
	BOOL ret = YES;
	{
		TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];
		
		CFMutableDictionaryRef dic = [self _getEmptyConfigDic];
		[pool autorelease:dic];
		
		ret = [self _setProxyDic:dic];
		ERROR_CHECK_BOOL(ret);
	}
	
Exit0:
	return ret;
}

- (CFMutableDictionaryRef)_getSocksConfigDic:(NSString*)host :(int)port
{
    CFMutableDictionaryRef proxyDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

	TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];

    CFMutableArrayRef exceptArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	[pool autorelease:exceptArray];
	
	CFArrayAppendValue(exceptArray, CFSTR("127.0.0.1"));
	CFArrayAppendValue(exceptArray, CFSTR("localhost"));
    CFDictionarySetValue(proxyDict, CFSTR("ExceptionsList"), exceptArray);
	
	int num = 1;
	CFNumberRef oneNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &num);
	[pool autorelease:oneNumber];
    CFDictionarySetValue(proxyDict, CFSTR("SOCKSEnable"), oneNumber);
	
	CFStringRef hostStr = CFStringCreateWithCString(kCFAllocatorDefault, [host UTF8String], kCFStringEncodingUTF8);
	[pool autorelease:hostStr];
    CFDictionarySetValue(proxyDict, CFSTR("SOCKSProxy"), hostStr);
	
	CFNumberRef portNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &port);
	[pool autorelease:portNumber];
    CFDictionarySetValue(proxyDict, CFSTR("SOCKSPort"), portNumber);
	
    return proxyDict;
}

- (CFMutableDictionaryRef)_getPACConfigDic:(NSString*)pacURL
{
	CFMutableDictionaryRef proxyDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

	TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];
	
	int num = 0;
	CFNumberRef zeroNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &num);
	[pool autorelease:zeroNumber];
	
	num = 1;
	CFNumberRef oneNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &num);
	[pool autorelease:oneNumber];
	
	num = 2;
	CFNumberRef twoNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &num);
	[pool autorelease:twoNumber];

	CFDictionarySetValue(proxyDict, CFSTR("HTTPEnable"), zeroNumber);
	CFDictionarySetValue(proxyDict, CFSTR("HTTPProxyType"), twoNumber);
	CFDictionarySetValue(proxyDict, CFSTR("HTTPSEnable"), zeroNumber);
	CFDictionarySetValue(proxyDict, CFSTR("ProxyAutoConfigEnable"), oneNumber);
	
	CFStringRef pacURLStr = CFStringCreateWithCString(kCFAllocatorDefault, [pacURL UTF8String], kCFStringEncodingUTF8);;
	[pool autorelease:pacURLStr];
	CFDictionarySetValue(proxyDict, CFSTR("ProxyAutoConfigURLString"), pacURLStr);
	
	return proxyDict;
}

- (CFMutableDictionaryRef)_getEmptyConfigDic
{
	CFMutableDictionaryRef proxyDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];

	int num = 0;
	CFNumberRef zeroNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &num);
	[pool autorelease:zeroNumber];
	
	CFDictionarySetValue(proxyDict, CFSTR("HTTPEnable"), zeroNumber);
	CFDictionarySetValue(proxyDict, CFSTR("HTTPProxyType"), zeroNumber);
	CFDictionarySetValue(proxyDict, CFSTR("HTTPSEnable"), zeroNumber);
	CFDictionarySetValue(proxyDict, CFSTR("ProxyAutoConfigEnable"), zeroNumber);
	
	return proxyDict;
}

- (BOOL)_setProxyDic:(CFMutableDictionaryRef)proxyDic
{
    BOOL ret = YES;
    {
        TTCFEasyReleasePool* pool = [TTCFEasyReleasePool new];

        CFIndex index;
		SCPreferencesRef pref = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, CFSTR("PrettyTunnel"), NULL, NULL);
        ERROR_CHECK_BOOLEX(pref, ret = NO);
        [pool autorelease:pref];

        CFDictionaryRef services = SCPreferencesGetValue(pref, CFSTR("NetworkServices"));
        ERROR_CHECK_BOOLEX(services, ret = NO);

        CFDictionaryRef serviceDict = CFDictionaryCreateCopy(kCFAllocatorDefault, services);
        ERROR_CHECK_BOOLEX(serviceDict, ret = NO);
        [pool autorelease:serviceDict];

        CFIndex count = CFDictionaryGetCount(serviceDict);
        CFTypeRef* keysTypeRef = (CFTypeRef*)malloc(count * sizeof(CFTypeRef));
        CFDictionaryGetKeysAndValues(serviceDict, (const void**)keysTypeRef, NULL);

        const void** allKeys = (const void**)keysTypeRef;
        for (index = 0; index < count; index++)
        {
            CFStringRef key = allKeys[index];
            CFDictionaryRef dict = CFDictionaryGetValue(serviceDict, key);
			
            CFStringRef rank = NULL;
            if (dict)
                rank = CFDictionaryGetValue(dict, CFSTR("PrimaryRank"));
            if (!rank || CFStringCompare(rank, CFSTR("Never"), 0) != kCFCompareEqualTo)
            {
                CFStringRef path = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("/NetworkServices/%@/Proxies"), key);
				[pool autorelease:path];
				
                ret = SCPreferencesPathSetValue(pref, path, proxyDic);
				ERROR_CHECK_BOOL(ret);
            }
        }
        free(allKeys);
		
        ret = SCPreferencesCommitChanges(pref);
		ERROR_CHECK_BOOL(ret);
        ret = SCPreferencesApplyChanges(pref);
		ERROR_CHECK_BOOL(ret);
        SCPreferencesSynchronize(pref);
		
        SCDynamicStoreRef store = SCDynamicStoreCreate(0, CFSTR("PrettyTunnel"), 0, 0);
		[pool autorelease:store];
    }

Exit0:
    return ret;
}

@end
