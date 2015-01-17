//
//  NSThread+SequenceNumber.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-10-16.
//
//

#import "NSThread+SequenceNumber.h"

@implementation NSThread (SequenceNumber)

- (NSUInteger)sequenceNumber
{
	return [[self valueForKeyPath:@"private.seqNum"] unsignedIntegerValue];
}

@end
