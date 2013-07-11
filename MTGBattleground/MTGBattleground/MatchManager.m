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
#import "UserService.h"
#import "Settings.h"
#import "NSArray+More.h"


static inline NSUInteger* randomIndexes(NSUInteger count) {
	NSUInteger* indexes = malloc(sizeof(NSUInteger) * count);
	for (NSUInteger i = 0; i < count; i++) {
		indexes[i] = i;
	}
	
	for (NSUInteger i = 0; i < count; i++) {
		NSUInteger value = indexes[i];
		NSUInteger randIndex = arc4random() % count;
		indexes[i] = indexes[randIndex];
		indexes[randIndex] = value;
	}
	
	return indexes;
}


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

+ (void)prepareMatchForPlaying:(Match *)match {
	if (!match.users) {
		NSArray *metas = [MatchService matchUserMetasForMatch:match];
		NSArray *users = [UserService usersForMatchUserMetas:metas]; // sets meta property and orders appropriately
		match.users = users;
	}
	NSAssert(match.users, @"Could not load Users for Match: %@", match);
	
	NSMutableDictionary *userIDDictionary = [[NSMutableDictionary alloc] initWithCapacity:[match.users count]];
	for (User *user in match.users) {
		[userIDDictionary setObject:user forKey:user.ID];
	}
	
	if (!match.currentTurn) {
		MatchTurn *currentMatchTurn = [MatchService latestMatchTurnForMatch:match offset:0];
		currentMatchTurn.user = [userIDDictionary objectForKey:currentMatchTurn.userID];
		
		match.currentTurn = currentMatchTurn;
	}
	NSAssert(match.currentTurn, @"Could not load Current Turn for Match: %@", match);
	
	// if first User has no State, assume none do and reset them all from DB
	if (![(User *)match.users[0] state]) {
		NSArray *userStates = [MatchService matchTurnUserStatesForMatchTurn:match.currentTurn];
		for (MatchTurnUserState *userState in userStates) {
			User *user = [userIDDictionary objectForKey:userState.userID];
			user.state = userState;
		}
	}
	
	// if first User has no Icon, assume none do and reset them all from DB
	if (![(User *)match.users[0] icon]) {
		NSArray *userIcons = [UserService userIconsForUsers:match.users];
		NSAssert([userIcons count] == [match.users count], @"UserIcons: %@ count does not match Users: %@ count", userIcons, match.users);
		
		NSUInteger i = 0;
		for (User *user in match.users) {
			user.icon = [userIcons objectAtIndex:i];
			i++;
		}
	}
}

+ (Match *)createMatchWithUsers:(NSArray *)users
				  userPositions:(NSArray *)userPositions
				   startingLife:(NSInteger)startingLife
					poisonToDie:(NSUInteger)poisonToDie
				  poisonCounter:(BOOL)poisonCounter
				dynamicCounters:(BOOL)dynamicCounters
				   turnTracking:(BOOL)turnTracking
					  autoDeath:(BOOL)autoDeath
				damageTargeting:(BOOL)damageTargeting {
	
	NSAssert([users count] >= 2, @"Cannot create Match with less than 2 Users: %@", users);
	NSAssert([users count] == [userPositions count], @"Users: %@ count and User Positions: %@ count must match", users, userPositions);
	
	NSMutableArray *mutableUsers = [users mutableCopy];
	
	Match *match = [[Match alloc] initWithID:[Service newGUID]
								winnerUserID:nil
								startingLife:startingLife
								 poisonToDie:poisonToDie
							   poisonCounter:poisonCounter
							 dynamicCounters:dynamicCounters
								turnTracking:turnTracking
								   autoDeath:autoDeath
							 damageTargeting:damageTargeting
									complete:NO
								   startTime:nil
									 endTime:nil];
	[MatchService insertMatch:match];
	
	// keeps starting states
	MatchTurn *initialTurn = [[MatchTurn alloc] initWithID:[Service newGUID]
												   matchID:match.ID
													userID:nil
												turnNumber:0
												  passTime:nil];
	[MatchService insertMatchTurn:initialTurn];
	
	NSUInteger* randIndexes = randomIndexes([mutableUsers count]);
	
	NSUInteger i = 0;
	User *startingUser;
	for (User *user in mutableUsers) {
		UserPosition userPosition = [userPositions[i] unsignedIntegerValue];
		NSUInteger turnOrder = randIndexes[i] + 1;
		
		MatchUserMeta *meta = [[MatchUserMeta alloc] initWithMatchID:match.ID
															  userID:user.ID
														   turnOrder:turnOrder
														userPosition:userPosition];
		
		user.meta = meta;
		
		if (turnOrder == 1) {
			startingUser = user;
		}
		
		i++;
	}
	NSAssert(startingUser, @"Starting User not found");
	
	free(randIndexes);

	// sort Users by Turn Order
	[mutableUsers sortUsingComparator:^NSComparisonResult(User *user1, User *user2) {
		return [@(user1.meta.turnOrder) compare:@(user2.meta.turnOrder)];
	}];
	
	match.users = mutableUsers; // runtime
	
	for (User *user in mutableUsers) {
		[MatchService insertMatchUserMeta:user.meta];
		
		MatchTurnUserState *state = [[MatchTurnUserState alloc] initWithMatchTurnID:initialTurn.ID
																			 userID:user.ID
																			   life:startingLife
																			 poison:0
																			 isDead:NO];
		[MatchService insertMatchTurnUserState:state];
	}
				
	MatchTurn *currentTurn = [[MatchTurn alloc] initWithID:[Service newGUID]
												   matchID:match.ID
													userID:startingUser.ID
												turnNumber:1
												  passTime:nil];
	currentTurn.user = startingUser;
	currentTurn.match = match;
	[MatchService insertMatchTurn:currentTurn];
	
	match.currentTurn = currentTurn; // runtime
	
	for (User *user in mutableUsers) {
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

+ (MatchTurn *)completeCurrentTurnForMatch:(Match *)match {
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
