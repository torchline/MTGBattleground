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
	
	self = [self init];
	if (self) {
		_matchID = matchID;
		_userID = userID;
		_turnOrder = turnOrder;
		_userPosition = userPosition;		
	}
	return self;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@: 0x%x matchID:%@ userID:%@ turnOrder:%d userPosition:%d>", NSStringFromClass([self class]), self.hash, _matchID, _userID, _turnOrder, _userPosition];
}

@end
