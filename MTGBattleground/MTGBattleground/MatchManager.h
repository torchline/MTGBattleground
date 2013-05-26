//
//  MatchManager.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MatchAccess.h"

@class Match;
@class MatchTurn;
@class User;

@interface MatchManager : NSObject

+ (void)setActiveMatch:(Match *)match;
+ (Match *)activeMatch;

+ (Match *)createMatchWithUsers:(NSArray *)users
				   startingLife:(NSInteger)startingLife
					poisonToDie:(NSUInteger)poisonToDie
				  poisonCounter:(BOOL)poisonCounter
				dynamicCounters:(BOOL)dynamicCounters
				   turnTracking:(BOOL)turnTracking
					  autoDeath:(BOOL)autoDeath;

+ (MatchTurn *)addMatchTurnToMatch:(Match *)match;
+ (void)revertMatchToBeginningOfCurrentTurn:(Match *)match;
+ (BOOL)revertMatchToPreviousTurn:(Match *)match;

@end
