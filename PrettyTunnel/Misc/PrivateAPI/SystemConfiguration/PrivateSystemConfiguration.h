//
//  PrivateSystemConfiguration.h
//  PrettyTunnel
//
//  Created by zhang fan on 15/1/15.
//
//

#ifndef PrettyTunnel_PrivateSystemConfiguration_h
#define PrettyTunnel_PrivateSystemConfiguration_h

#include <CoreFoundation/CoreFoundation.h>

typedef const struct __SCPreferences* SCPreferencesRef;
typedef const struct AuthorizationOpaqueRef* AuthorizationRef;
typedef const struct __SCDynamicStore* SCDynamicStoreRef;
typedef void (*SCDynamicStoreCallBack)(SCDynamicStoreRef store, CFArrayRef changedKeys, void* info);

typedef struct
{
	CFIndex version;
	void* info;
	const void* (*retain)(const void* info);
	void (*release)(const void* info);
	CFStringRef (*copyDescription)(const void* info);
} SCDynamicStoreContext;

SCPreferencesRef SCPreferencesCreate(CFAllocatorRef allocator, CFStringRef name, CFStringRef prefsID);
SCPreferencesRef SCPreferencesCreateWithAuthorization(CFAllocatorRef allocator, CFStringRef name, CFStringRef prefsID, AuthorizationRef authorization);
CFPropertyListRef SCPreferencesGetValue(SCPreferencesRef prefs, CFStringRef key);
Boolean SCPreferencesPathSetValue(SCPreferencesRef prefs, CFStringRef path, CFDictionaryRef value);
Boolean SCPreferencesCommitChanges(SCPreferencesRef prefs);
Boolean SCPreferencesApplyChanges(SCPreferencesRef prefs);
void SCPreferencesSynchronize(SCPreferencesRef prefs);

SCDynamicStoreRef SCDynamicStoreCreate(CFAllocatorRef allocator, CFStringRef name, SCDynamicStoreCallBack callout, SCDynamicStoreContext* context);

#endif
