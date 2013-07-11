//
//  MatchTurnUserDamage.h
//  MTGBattleground
//
//  Created by Brad Walker on 6/30/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MatchTurnUserDamage : NSObject

@property (nonatomic) NSString *matchTurnID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *damagedUserID;
@property (nonatomic) NSInteger lifeDamage;
@property (nonatomic) NSInteger poisonDamage;

- (MatchTurnUserDamage *)initWithMatchTurnID:(NSString *)matchTurnID
									  userID:(NSString *)userID
							   damagedUserID:(NSString *)damagedUserID
								  lifeDamage:(NSInteger)lifeDamage
								poisonDamage:(NSInteger)poisonDamage;

@end
