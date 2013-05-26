//
//  User.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "User+Runtime.h"

@implementation User

#pragma mark - Init

- (User *)initWithID:(NSString *)ID
				name:(NSString *)name
		  userIconID:(NSUInteger)userIconID
		numTimesUsed:(NSUInteger)numTimesUsed
		lastTimeUsed:(NSDate *)lastTimeUsed {
	
	self = [super init];
	if (self) {
		_ID = ID;
		_name = name;
		_userIconID = userIconID;
		_numTimesUsed = numTimesUsed;
		_lastTimeUsed = lastTimeUsed;
	}
	return self;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@ 0x%x id=%@ name=%@>", NSStringFromClass([self class]), self.hash, self.ID, self.name];
}

@end
