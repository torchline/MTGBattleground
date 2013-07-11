//
//  UserState.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/19/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MatchTurnUserState : NSObject

@property (nonatomic) NSString *matchTurnID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSInteger life;
@property (nonatomic) NSUInteger poison;
@property (nonatomic) BOOL isDead;

- (MatchTurnUserState *)initWithMatchTurnID:(NSString *)matchTurnID
									 userID:(NSString *)userID
									   life:(NSInteger)life
									 poison:(NSUInteger)poison
									 isDead:(BOOL)isDead;

@end
