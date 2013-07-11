//
//  UserState.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/19/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchTurnUserState.h"

@implementation MatchTurnUserState

#pragma mark - Init

- (MatchTurnUserState *)initWithMatchTurnID:(NSString *)matchTurnID
									userID:(NSString *)userID
								  life:(NSInteger)life
								poison:(NSUInteger)poison
								isDead:(BOOL)isDead {
	
	self = [super init];
	if (self) {
		_matchTurnID = matchTurnID;
		_userID = userID;
		_life = life;
		_poison = poison;
		_isDead = isDead;		
	}
	return self;
}

- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@: 0x%x userID=%@ life=%d poison=%d dead=%d>", NSStringFromClass([self class]), self.hash, _userID, _life, _poison, _isDead];
}

@end
