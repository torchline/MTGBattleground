//
//  Match.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Match.h"

@implementation Match

#pragma mark - Init

- (Match *)initWithID:(NSString *)ID
		 winnerUserID:(NSString *)winnerUserID
		 startingLife:(NSInteger)startingLife
		  poisonToDie:(NSUInteger)poisonToDie
		poisonCounter:(BOOL)poisonCounter
	  dynamicCounters:(BOOL)dynamicCounters
		 turnTracking:(BOOL)turnTracking
			autoDeath:(BOOL)autoDeath
	  damageTargeting:(BOOL)damageTargeting
			 complete:(BOOL)complete
			startTime:(NSDate *)startTime
			  endTime:(NSDate *)endTime {
	
	self = [super init];
	if (self) {
		_ID = ID;
		_winnerUserID = winnerUserID;
		_startingLife = startingLife;
		_poisonToDie = poisonToDie;
		_enablePoisonCounter = poisonCounter;
		_enableDynamicCounters = dynamicCounters;
		_enableTurnTracking = turnTracking;
		_enableAutoDeath = autoDeath;
		_enableDamageTargeting = damageTargeting;
		_isComplete = complete;
		_startTime = startTime;
		_endTime = endTime;
	}
	return self;
}

@end
