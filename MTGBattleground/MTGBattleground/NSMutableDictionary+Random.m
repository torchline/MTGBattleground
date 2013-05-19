//
//  NSMutableDictionary+Random.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/18/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "NSMutableDictionary+Random.h"

@implementation NSMutableDictionary (Random)

- (id <NSCopying>)randomKey {
	if (![self count]) {
		return nil;
	}
	
	NSUInteger index = arc4random() % [self count];
	return [[self allKeys] objectAtIndex:index];
}

- (id)randomObject {
	if (![self count]) {
		return nil;
	}
	
	id <NSCopying> key = [self randomKey];
	return [self objectForKey:key];
}

@end
