//
//  MatchManager.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Match;
@class MatchTurn;
@class LocalUser;

@interface MatchManager : NSObject

+ (Match *)createMatchWithLocalUsers:(NSArray *)localUsers
						startingLife:(NSUInteger)startingLife
					   poisonCounter:(BOOL)poisonCounter
					 dynamicCounters:(BOOL)dynamicCounters
						  turnTracking:(BOOL)turnTracking;

+ (MatchTurn *)createMatchTurnWithMatch:(Match *)match activeLocalUser:(LocalUser *)activeLocalUser allLocalUsers:(NSArray *)allLocalUsers;

+ (void)deleteActiveMatch:(Match *)match;

+ (void)resetMatchToPreviousTurnState:(Match *)match localUsers:(NSArray *)localUsers;

@end
