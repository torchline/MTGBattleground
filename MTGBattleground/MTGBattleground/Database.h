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

@interface Database : NSObject


// CREATE
+ (void)createMatch:(Match *)match;
+ (void)createLocalUserParticipants:(NSArray *)users forMatch:(Match *)match;
+ (void)createMatchTurn:(MatchTurn *)matchTurn;
+ (void)createLocalUserStates:(NSArray *)users forMatchTurn:(MatchTurn *)matchTurn;
+ (void)createLocalUserActiveStates:(NSArray *)localUsers forMatch:(Match *)match;

// READ
+ (NSMutableArray *)matches;
+ (Match *)matchWithID:(NSString *)ID;
+ (Match *)activeMatch;

+ (NSMutableArray *)matchTurnsForMatch:(Match *)match;
+ (MatchTurn *)lastMatchTurnForMatch:(Match *)match;

+ (NSMutableArray *)localUsersParticipatingInMatch:(Match *)match activeLocalUser:(LocalUser *__autoreleasing*)activeUser;

+ (NSMutableArray *)localUsers;

+ (NSMutableArray *)userIcons;


// UPDATE
+ (void)updateLocalUser:(LocalUser *)localUser;
+ (void)updateLocalUserUserState:(LocalUser *)user;


// DELETE
+ (void)deleteMatch:(Match *)match;
+ (void)deleteMatchTurn:(MatchTurn *)matchTurn;

+ (void)deleteLocalUserActiveStatesForMatch:(Match *)match;

// Misc
+ (FMDatabaseQueue *)fmDatabaseQueue;
+ (dispatch_queue_t)backgroundQueue;
+ (NSString *)newGUID;
+ (NSMutableDictionary *)idDictionaryForDatabaseObjects:(NSArray *)dbObjects;

@end
