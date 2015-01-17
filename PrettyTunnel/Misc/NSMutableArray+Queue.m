//
//  NSMutableArray+Queue.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-8-7.
//
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (id) head
{
	if (![self count])
		return nil;
	
	return [self objectAtIndex:0];
}

- (id) dequeue
{
    if (![self count])
		return nil;
	
    id headObject = [self objectAtIndex:0];
        [self removeObjectAtIndex:0];
	
    return headObject;
}

- (void) enqueue:(id)anObject
{
    [self addObject:anObject];
}

@end
