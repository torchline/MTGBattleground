//
//  NSMutableArray+Shifting.m
//  ScramblerFramework
//
//  Created by Brad Walker on 7/20/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import "NSMutableArray+Shifting.h"


@implementation NSMutableArray (Shifting)

- (NSMutableArray *)initWithArray:(NSArray *)array shuffled:(BOOL)shuffled {
	self = [super initWithArray:array];
	if (self) {
		if (shuffled) {
			[self shuffle];
		}
	}
	return self;
}

- (void)swapObjectsAtIndex:(NSInteger)firstIndex andIndex:(NSInteger)secondIndex {
	NSObject *firstObject = [self objectAtIndex:firstIndex];
	NSObject *secondObject = [self objectAtIndex:secondIndex];
	[self replaceObjectAtIndex:firstIndex withObject:secondObject];
	[self replaceObjectAtIndex:secondIndex withObject:firstObject];
}

- (void)swapIndexesOfObject:(NSObject *)firstObject andObject:(NSObject *)secondObject {
	NSInteger firstIndex = [self indexOfObject:firstObject];
	NSInteger secondIndex = [self indexOfObject:secondObject];
	
	if (firstIndex != NSNotFound && secondIndex != NSNotFound) {
		[self replaceObjectAtIndex:firstIndex withObject:secondObject];
		[self replaceObjectAtIndex:secondIndex withObject:firstObject];
	}
}

- (void)shiftObjectAtIndex:(NSInteger)firstIndex toIndex:(NSInteger)secondIndex {
	NSObject *firstObject = [self objectAtIndex:firstIndex];
	[self removeObjectAtIndex:firstIndex];
	[self insertObject:firstObject atIndex:secondIndex];
}

- (void)shiftObject:(NSObject *)object toIndex:(NSInteger)index {
	[self removeObject:object];
	[self insertObject:object atIndex:index];
}

- (void)shuffle {
	for (int i = 0; i < [self count]; i++) {
		NSInteger randIndex = arc4random() % [self count];
		if (randIndex != i) {
			[self swapObjectsAtIndex:randIndex andIndex:i];
		}
	}
}

@end
