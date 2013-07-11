//
//  MatchTurnUserDamage.m
//  MTGBattleground
//
//  Created by Brad Walker on 6/30/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchTurnUserDamage.h"

@implementation MatchTurnUserDamage


#pragma mark - Init

- (MatchTurnUserDamage *)initWithMatchTurnID:(NSString *)matchTurnID
									  userID:(NSString *)userID
							   damagedUserID:(NSString *)damagedUserID
									  lifeDamage:(NSInteger)lifeDamage
								poisonDamage:(NSInteger)poisonDamage {
	self = [super init];
	if (self) {
		_matchTurnID = matchTurnID;
		_userID = userID;
		_damagedUserID = damagedUserID;
		_lifeDamage = lifeDamage;
		_poisonDamage = poisonDamage;
	}
	return self;
}


#pragma mark - Getter / Setter
- (NSString *)description {
	return [[NSString alloc] initWithFormat:@"<%@: 0x%x userID:%@ damagedUserID:%@ lifeDamage:%d poisonDamage:%d>", NSStringFromClass([self class]), self.hash, _userID, _damagedUserID, _lifeDamage, _poisonDamage];
}

@end
