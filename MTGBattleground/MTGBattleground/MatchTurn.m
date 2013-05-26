//
//  MatchTurn.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchTurn.h"

@implementation MatchTurn

#pragma mark - Init

- (MatchTurn *)initWithID:(NSString *)ID
				  matchID:(NSString *)matchID
				   userID:(NSString *)userID
			   turnNumber:(NSUInteger)turnNumber
				 passTime:(NSDate *)passTime {
	
	self = [super init];
	if (self) {
		_ID = ID;
		_matchID = matchID;
		_userID = userID;
		_turnNumber = turnNumber;
		_passTime = passTime;
	}
	return self;
}

@end
