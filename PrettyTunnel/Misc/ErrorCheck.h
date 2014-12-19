/* -------------------------------------------------------------------------
//	File Name	:	ErrorCheck.h
//	Author		:	Zhang Fan
//	Create Time	:	2012-3-19 16:49:55
//	Description	:   error check and code path control
//
// -----------------------------------------------------------------------*/

#ifndef __ERRORCHECK_H__
#define __ERRORCHECK_H__

// #define DISABLE_ASSERT

//---------------------------------------------------------------------------
#ifdef _MSC_VER
#define __X_FUNCTION__ __FUNCTION__
#else
#define __X_FUNCTION__ __PRETTY_FUNCTION__
#endif

#if defined(_DEBUG) && !defined(DISABLE_ASSERT)

    #if defined (_WIN32) || defined(_WIN64)
        #include <crtdbg.h>
        #define X_ASSERT(exp)               \
        do                                      \
        {                                       \
            _ASSERT(exp);                       \
        } while (0)
        
    #elif defined (__APPLE__)
		#include "TargetConditionals.h"
		#if defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR)
			#if defined(__i386__) || defined(__x86_64__) // iOS simulator
				#define X_ASSERT(exp)					\
				do                                      \
				{                                       \
					if (!(exp))							\
						asm("int $3");					\
				} while (0)

			#elif defined(__arm__) || defined(__arm64__) // iOS device
				#include <signal.h>
				#include <pthread.h>

				#define X_ASSERT(exp)								\
				do													\
				{													\
					if (!(exp))										\
						pthread_kill(pthread_self(), SIGINT);		\
				} while (0)
			#endif

		#elif defined(TARGET_OS_MAC)					 // Mac OS
			#include <CoreFoundation/CoreFoundation.h>
			#define X_ASSERT(exp)\
			do                                      \
			{                                       \
				if (!(exp))                         \
				{                                   \
					CFUserNotificationDisplayAlert(10, kCFUserNotificationNoteAlertLevel, NULL, NULL, NULL, CFSTR(#exp), NULL, NULL, NULL, NULL, NULL);\
					asm("int $3");                  \
				}                                   \
			} while (0)
		#endif
    #else
        #include <assert.h>

        #define X_ASSERT(exp)					\
        do                                      \
        {                                       \
            assert(exp);                        \
        } while (0)
        
    #endif
#else
    #define X_ASSERT(exp)						\
    do                                          \
    {                                           \
        if (!(exp))                             \
			DDLogError(@"Assert Faild: %s, %s, %s(%d)", #exp, __X_FUNCTION__, __FILE__, __LINE__);				\
    } while (0)
    
#endif

// -------------------------------------------------------------------------

#define CHECK_BOOL(exp)														\
    do {																	\
        if (!(exp))															\
        {																	\
            goto Exit0;														\
        }																	\
    } while(0)

#define ERROR_CHECK_BOOL(exp)												\
    do {																	\
    if (!(exp))															    \
        {																	\
        X_ASSERT(!"ERROR_CHECK_BOOL:" #exp);							\
        goto Exit0;														    \
        }																	\
    } while(0)

#define CHECK_BOOLEX(exp, exp1)												\
    do {																	\
    if (!(exp))															    \
        {																	\
        exp1;															    \
        goto Exit0;														    \
        }																	\
    } while(0)

#define ERROR_CHECK_BOOLEX(exp, exp1)										\
    do {																	\
    if (!(exp))			    												\
        {																	\
        X_ASSERT(!"ERROR_CHECK_BOOLEX" #exp);								\
        exp1;															    \
        goto Exit0;														    \
        }																	\
    } while(0)

#define QUIT()          \
    do                  \
    {                   \
    goto Exit0;         \
    } while (0)

//--------------------------------------------------------------------------
#endif /* __ERRORCHECK_H__ */