//
//  MatchUserMeta.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchUserMeta.h"

@implementation MatchUserMeta

#pragma mark - Init

- (MatchUserMeta *)initWithMatchID:(NSString *)matchID
							userID:(NSString *)userID
						 turnOrder:(NSUInteger)turnOrder
					  userPosition:(UserPosition)userPosition {
	
	self = [super init];
	if (self) {
		_matchID = matchID;
		_userID = userID;
		_turnOrder = turnOrder;
		_userPosition = userPosition;		
	}
	return self;
}

@end
