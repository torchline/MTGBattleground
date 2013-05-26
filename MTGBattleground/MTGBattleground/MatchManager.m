//
//  MatchManager.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchManager.h"

#import "Match+Runtime.h"
#import "MatchTurn+Runtime.h"
#import "User+Runtime.h"

#import "MatchService.h"
#import "Settings.h"
#import "NSArray+More.h"


@implementation MatchManager

+ (void)setActiveMatch:(Match *)match {
	[Settings setString:match.ID forKey:SETTINGS_CURRENT_ACTIVE_MATCH_ID];
}

+ (Match *)activeMatch {
	NSString *activeMatchID = [Settings stringForKey:SETTINGS_CURRENT_ACTIVE_MATCH_ID];
	if (!activeMatchID) {
		return nil;
	}
	
	Match *activeMatch = [MatchService matchWithID:activeMatchID];
	if (!activeMatch) {
		[Settings setString:nil forKey:SETTINGS_CURRENT_ACTIVE_MATCH_ID];
	}
	
	return activeMatch;
}

+ (Match *)createMatchWithUsers:(NSArray *)users
				   startingLife:(NSInteger)startingLife
					poisonToDie:(NSUInteger)poisonToDie
				  poisonCounter:(BOOL)poisonCounter
				dynamicCounters:(BOOL)dynamicCounters
				   turnTracking:(BOOL)turnTracking
					  autoDeath:(BOOL)autoDeath {
	
	Match *match = [[Match alloc] initWithID:[Service newGUID]
								winnerUserID:nil
								startingLife:startingLife
								 poisonToDie:poisonToDie
							   poisonCounter:poisonCounter
							 dynamicCounters:dynamicCounters
								turnTracking:turnTracking
								   autoDeath:autoDeath
									complete:NO
								   startTime:nil
									 endTime:nil];
	match.users = users;
	[MatchService insertMatch:match];
	
	NSUInteger i = 0;
	for (User *user in users) {
		MatchUserMeta *meta = [[MatchUserMeta alloc] initWithMatchID:match.ID
															  userID:user.ID
														   turnOrder:(i + 1)
														userPosition:(i + 1)]; // TODO: meta user position
		
		[MatchService insertMatchUserMeta:meta];
		
		user.meta = meta;
		
		i++;
	}
	
	match.users = users; // runtime
	
	// keeps starting states
	MatchTurn *initialTurn = [[MatchTurn alloc] initWithID:[Service newGUID]
												   matchID:match.ID
													userID:nil
												turnNumber:0
												  passTime:nil];
	[MatchService insertMatchTurn:initialTurn];
	
	for (User *user in users) {
		MatchTurnUserState *state = [[MatchTurnUserState alloc] initWithMatchTurnID:initialTurn.ID
																			 userID:user.ID
																			   life:startingLife
																			 poison:0
																			 isDead:NO];
		[MatchService insertMatchTurnUserState:state];
	}
	
	User *startingUser = [users objectAtIndex:0];
	
	MatchTurn *currentTurn = [[MatchTurn alloc] initWithID:[Service newGUID]
												   matchID:match.ID
													userID:startingUser.ID
												turnNumber:1
												  passTime:nil];
	currentTurn.user = startingUser;
	currentTurn.match = match;
	[MatchService insertMatchTurn:currentTurn];
	
	match.currentTurn = currentTurn; // runtime
	
	for (User *user in users) {
		MatchTurnUserState *state = [[MatchTurnUserState alloc] initWithMatchTurnID:currentTurn.ID
																			 userID:user.ID
																			   life:startingLife
																			 poison:0
																			 isDead:NO];
		[MatchService insertMatchTurnUserState:state];
		
		user.state = state;
	}
	
	return match;
}

+ (MatchTurn *)addMatchTurnToMatch:(Match *)match {
	NSAssert(match.enableTurnTracking, @"Should not be creating MatchTurns when Match (%@) has TurnTracking off", match.ID);
		
	// find next user
	NSUInteger checkCount = 0;
	NSUInteger maxCheckCount = [match.users count];
	User *nextUser = [match.users objectAfterObject:match.currentTurn.user];
	while (nextUser.state.isDead && checkCount < maxCheckCount) {
		nextUser = [match.users objectAfterObject:nextUser];
		checkCount++;
	}
	
	if (checkCount == maxCheckCount) {
		nextUser = nil;
	}

	NSAssert(nextUser, @"Could not find next user");

	// save current MatchTurn
	match.currentTurn.passTime = [NSDate date];
	[MatchService updateMatchTurn:match.currentTurn];
	
	// create new MatchTurn
	MatchTurn *matchTurn = [[MatchTurn alloc] initWithID:[Service newGUID]
												 matchID:match.ID
												  userID:nextUser.ID
											  turnNumber:(match.currentTurn.turnNumber + 1)
												passTime:nil];
	matchTurn.user = nextUser;
	matchTurn.match = match;
		
	for (User *user in match.users) {
		user.state.matchTurnID = matchTurn.ID;
	}
	
	// persist new MatchTurn and create new states (for current)
	dispatch_async([Service backgroundQueue], ^{
		[MatchService insertMatchTurn:matchTurn];
		
		for (User *user in match.users) {
			[MatchService insertMatchTurnUserState:user.state];
		}
	});
	
	match.currentTurn = matchTurn;
	
	return matchTurn;
}

+ (void)revertMatchToBeginningOfCurrentTurn:(Match *)match {
	NSAssert(match.currentTurn, @"Match has no current turn");
	NSAssert(match.currentTurn.turnNumber > 0, @"The current turn number should never be 0");
	
	MatchTurn *matchTurnToRestore = [MatchService latestMatchTurnForMatch:match offset:1]; // last turn that is not current
	NSAssert(matchTurnToRestore, @"Could not find MatchTurn to restore");
	
	NSDictionary *userStatesToRestoreDictionary = [MatchService matchTurnUserStateDictionaryForMatchTurn:matchTurnToRestore];
	
	for (User *user in match.users) {
		MatchTurnUserState *userStateToRestore = [userStatesToRestoreDictionary objectForKey:user.ID];
		NSAssert(userStateToRestore, @"UserState for %@ should not be nil", user.ID);
		
		userStateToRestore.matchTurnID = match.currentTurn.ID;
		user.state = userStateToRestore;
		
		[MatchService updateMatchTurnUserState:user.state];
	}	
}

+ (BOOL)revertMatchToPreviousTurn:(Match *)match {
	NSAssert(match.currentTurn, @"Match has no current turn to delete");
	NSAssert(match.currentTurn.turnNumber > 1, @"The current turn number should be greater than 1");
	
	MatchTurn *matchTurnToRestore = [MatchService latestMatchTurnForMatch:match offset:2];
	NSAssert(matchTurnToRestore, @"Could not find MatchTurn to restore");
	
	MatchTurn *newCurrentMatchTurn = [MatchService latestMatchTurnForMatch:match offset:1];
	NSAssert(newCurrentMatchTurn, @"Could not find new current MatchTurn");
	newCurrentMatchTurn.match = match;
	newCurrentMatchTurn.passTime = nil;
	
	NSDictionary *userStatesToRestoreDictionary = [MatchService matchTurnUserStateDictionaryForMatchTurn:matchTurnToRestore];
	
	for (User *user in match.users) {
		MatchTurnUserState *userStateToRestore = [userStatesToRestoreDictionary objectForKey:user.ID];
		NSAssert(userStateToRestore, @"UserState for %@ should not be nil", user.ID);
		
		userStateToRestore.matchTurnID = newCurrentMatchTurn.ID;
		user.state = userStateToRestore;
		
		if ([user.ID isEqualToString:newCurrentMatchTurn.userID]) {
			newCurrentMatchTurn.user = user;
		}
	}
		
	NSAssert(newCurrentMatchTurn.user, @"Could not find User for MatchTurn");
	
	[MatchService deleteMatchTurn:match.currentTurn];
	
	match.currentTurn = newCurrentMatchTurn;
	
	return YES;
}


@end
