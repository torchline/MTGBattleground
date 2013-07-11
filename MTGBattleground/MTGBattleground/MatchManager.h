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

// sets Active Match in Settings to keep track of currently running Match.
// Upon app re-launch, Active Match is opened if exists.
+ (void)setActiveMatch:(Match *)match;
+ (Match *)activeMatch;

// populates all necessary runtime properties of Match object such as Users, Turns, and Meta.
// Only needed when reloading a persisted Match, not when first creating it.
+ (void)prepareMatchForPlaying:(Match *)match;

// creates a Match from Match Setup screen
+ (Match *)createMatchWithUsers:(NSArray *)users
				  userPositions:(NSArray *)userPositions
				   startingLife:(NSInteger)startingLife
					poisonToDie:(NSUInteger)poisonToDie
				  poisonCounter:(BOOL)poisonCounter
				dynamicCounters:(BOOL)dynamicCounters
				   turnTracking:(BOOL)turnTracking
					  autoDeath:(BOOL)autoDeath
				damageTargeting:(BOOL)damageTargeting;

// Adds a Turn to a Match after it has been played
+ (MatchTurn *)completeCurrentTurnForMatch:(Match *)match;

// Resets Match state to state at end of last turn 
+ (void)revertMatchToBeginningOfCurrentTurn:(Match *)match;

// Resets Match state to state at end of last, last turn
+ (BOOL)revertMatchToPreviousTurn:(Match *)match;

@end
