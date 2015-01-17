//
//  KPCommonDef.h
//  PrettyTunnel
//
//  Created by zhang fan on 14-7-10.
//
//

#define kKiloByte								1024
#define kMegaByte								(1024 * 1024)
#define kGagaByte								(1024 * 1024 * 1024)

#define kSeconds1Day							(60 * 60 * 24)
#define kSeconds1Hour							(60 * 60)
#define kSeconds1Min							60

#define LString(key) \
[[NSBundle mainBundle] localizedStringForKey:key value:key table:nil]
