//
//  MatchService.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Service.h"


@class Match;
@class MatchUserMeta;
@class MatchTurn;
@class MatchTurnUserState;
@class MatchTurnUserDamage;


@interface MatchService : Service

// Match
+ (NSUInteger)numberOfMatches;
+ (NSMutableArray *)matchesWithLimit:(NSUInteger)limit offset:(NSUInteger)offset;
+ (Match *)matchWithID:(NSString *)matchID;
+ (void)insertMatch:(Match *)match;
+ (void)updateMatch:(Match *)match;
+ (void)deleteMatch:(Match *)match;

// MatchUserMeta
+ (NSMutableArray *)matchUserMetasForMatch:(Match *)match;
+ (void)insertMatchUserMeta:(MatchUserMeta *)meta;

// MatchTurn
+ (MatchTurn *)matchTurnPreviousToMatchTurn:(MatchTurn *)matchTurn;
+ (NSMutableArray *)matchTurnsForMatch:(Match *)match;
+ (MatchTurn *)latestMatchTurnForMatch:(Match *)match offset:(NSUInteger)offset;
+ (void)insertMatchTurn:(MatchTurn *)matchTurn;
+ (void)updateMatchTurn:(MatchTurn *)matchTurn;
+ (void)deleteMatchTurn:(MatchTurn *)matchTurn;

// MatchTurnUserState
+ (NSMutableArray *)matchTurnUserStatesForMatchTurn:(MatchTurn *)matchTurn;
+ (NSMutableDictionary *)matchTurnUserStateDictionaryForMatchTurn:(MatchTurn *)matchTurn;
+ (void)insertMatchTurnUserState:(MatchTurnUserState *)userState;
+ (void)updateMatchTurnUserState:(MatchTurnUserState *)userState;

// MatchTurnUserDamage
+ (NSMutableArray *)matchTurnUserDamagesForMatchTurn:(MatchTurn *)matchTurn;
+ (void)insertMatchTurnUserDamage:(MatchTurnUserDamage *)userDamage;

@end
