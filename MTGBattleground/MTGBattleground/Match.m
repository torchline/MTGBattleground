//
//  Match.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Match.h"

@implementation Match

- (id)init {
	self = [super init];
	if (self) {
		_startingLife = 20;
		_poisonToDie = 10;
		_enablePoisonCounter = YES;
		_enableDynamicCounters = YES;
		_enableTurnTracking = YES;
		_enableAutoDeath = YES;
		_isComplete = NO;
	}
	return self;
}

- (id)identifiableID {
	return self.ID;
}

@end
