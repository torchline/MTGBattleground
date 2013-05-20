//
//  Database.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Match;
@class MatchTurn;
@class LocalUser;
@class FMDatabaseQueue;
@class UserState;

@interface Database : NSObject


// CREATE
+ (void)createMatch:(Match *)match;
+ (void)createInitialUserStates:(NSArray *)users forMatch:(Match *)match;
+ (void)createMatchTurn:(MatchTurn *)matchTurn;
+ (void)createUserStates:(NSArray *)users forMatchTurn:(MatchTurn *)matchTurn;
+ (void)createCurrentUserStates:(NSArray *)userStates forMatch:(Match *)match;

// READ
+ (NSMutableArray *)matches;
+ (Match *)matchWithID:(NSString *)ID;
+ (Match *)activeMatch;
+ (NSMutableArray *)initialUserStatesForMatch:(Match *)match;

+ (NSMutableArray *)matchTurnsForMatch:(Match *)match;
+ (MatchTurn *)lastMatchTurnForMatch:(Match *)match;
+ (MatchTurn *)secondToLastMatchTurnForMatch:(Match *)match;

+ (NSMutableArray *)localUsersParticipatingInMatch:(Match *)match activeLocalUser:(LocalUser *__autoreleasing*)activeUser;

+ (NSMutableArray *)localUsers;

+ (NSMutableArray *)userStatesForMatchTurn:(MatchTurn *)matchTurn;

+ (NSMutableArray *)userIcons;


// UPDATE
+ (void)updateLocalUser:(LocalUser *)localUser;
+ (void)updateUserStateForActiveMatch:(UserState *)userState;


// DELETE
+ (void)deleteMatch:(Match *)match;
+ (void)deleteMatchTurn:(MatchTurn *)matchTurn;


// Misc
+ (FMDatabaseQueue *)fmDatabaseQueue;
+ (dispatch_queue_t)backgroundQueue;
+ (NSString *)newGUID;
+ (NSMutableDictionary *)idDictionaryForDatabaseObjects:(NSArray *)dbObjects;

@end
