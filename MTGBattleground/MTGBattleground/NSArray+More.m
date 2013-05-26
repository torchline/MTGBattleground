//
//  NSMutableArray+Queueing.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "NSArray+More.h"

@implementation NSArray (More)

- (id)objectAfterObject:(id)object {
	NSUInteger index = [self indexOfObject:object];
	NSAssert(index != NSNotFound, @"Object %@ not found in array", object);
	
	NSUInteger nextIndex;
	if (index == [self count]-1) { // is last object
		nextIndex = 0;
	}
	else {
		nextIndex = index + 1;
	}
	
	return [self objectAtIndex:nextIndex];
}

@end
