//
//  MatchManager.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchManager.h"
#import "Match.h"
#import "Database.h"
#import "MatchTurn.h"
#import "LocalUser.h"

@implementation MatchManager

+ (Match *)createMatchWithLocalUsers:(NSArray *)localUsers
						startingLife:(NSUInteger)startingLife
					   poisonCounter:(BOOL)poisonCounter
					 dynamicCounters:(BOOL)dynamicCounters
						  turnTracking:(BOOL)turnTracking {
	
	NSAssert([localUsers count], @"Cannot create a Match without any users");
	
	// create Match
	Match *match = [Match new];
	match.ID = [Database newGUID];
	match.startingLife = startingLife;
	match.enablePoisonCounter = poisonCounter;
	match.enableDynamicCounters = dynamicCounters;
	match.enableTurnTracking = turnTracking;
	match.startDate = [NSDate date];
	
	// persist Match
	[Database createMatch:match];
	
	// initialize user states
	for (LocalUser *localUser in localUsers) {
		NSAssert(localUser.state, @"Expecting LocalUser to have at least a partial state (to hold UserSlot) before creating Match");
		NSAssert(localUser.state.userSlot > 0, @"Expecting LocalUser to have a UserSlot set prior to creating Match");
		
		localUser.state.localUserID = localUser.ID;
		localUser.state.life = startingLife;
		localUser.state.poison = 0;		
	}
	
	NSArray *userStates = [self userStatesFromLocalUsers:localUsers];
	
	[Database createInitialUserStates:userStates forMatch:match];
	[Database createCurrentUserStates:userStates forMatch:match];
	
	return match;
}

+ (MatchTurn *)createMatchTurnWithMatch:(Match *)match activeLocalUser:(LocalUser *)activeLocalUser allLocalUsers:(NSArray *)allLocalUsers {
	NSAssert(match.enableTurnTracking, @"Should not be creating MatchTurns when Match (%@) has TurnTracking off", match.ID);
	
	// create MatchTurn
	MatchTurn *matchTurn = [MatchTurn new];
	matchTurn.ID = [Database newGUID];
	matchTurn.matchID = match.ID;
	matchTurn.localUserID = activeLocalUser.ID;
	matchTurn.endDate = [NSDate date];
	
	// persist MatchTurn
	dispatch_async([Database backgroundQueue], ^{
		[Database createMatchTurn:matchTurn];
		[Database createUserStates:[self userStatesFromLocalUsers:allLocalUsers] forMatchTurn:matchTurn];
	});
	
	return matchTurn;
}

+ (void)deleteActiveMatch:(Match *)match {
	dispatch_async([Database backgroundQueue], ^{
		[Database deleteMatch:match];
	});
}

+ (void)restorePreviousUserStatesForMatch:(Match *)match localUsers:(NSArray *)localUsers activeLocalUser:(LocalUser *__autoreleasing*)activeLocalUser {
	MatchTurn *matchTurnToDelete = [Database lastMatchTurnForMatch:match];
	NSAssert(matchTurnToDelete, @"No previous MatchTurn exists");
	
	MatchTurn *matchTurnToRestoreFrom = [Database secondToLastMatchTurnForMatch:match];
	
	if (matchTurnToRestoreFrom) { // at least two turns have been stored
		NSDictionary *userStatesToRestoreIDDictionary = [Database idDictionaryForDatabaseObjects:[Database userStatesForMatchTurn:matchTurnToRestoreFrom]];
		
		for (LocalUser *localUser in localUsers) {
			// UserStates are identified by LocalUserID (right now). May change later for better decoupling.
			UserState *userStateToRestore = [userStatesToRestoreIDDictionary objectForKey:@(localUser.ID)];
			NSAssert(userStateToRestore, @"UserState should not be nil");
			
			localUser.state = userStateToRestore;
		}
		
		if (activeLocalUser) {
			for (LocalUser *localUser in localUsers) {
				if (localUser.ID == matchTurnToDelete.localUserID) {
					*activeLocalUser = localUser;
					break;
				}
			}
			
			NSAssert(*activeLocalUser, @"Could not find active LocalUser");
		}
	}
	else { // state to restore is intiial Match state
		NSArray *initialUserStates = [Database initialUserStatesForMatch:match];
		UserState *initialActiveUserState = [initialUserStates objectAtIndex:0];
		
		for (LocalUser *localUser in localUsers) {
			// UserStates are identified by LocalUserID (right now). May change later for better decoupling.
			UserState *initialUserState = [[UserState alloc] init];
			initialUserState.localUserID = localUser.ID;
			initialUserState.userSlot = localUser.state.userSlot;
			initialUserState.life = match.startingLife;
			initialUserState.poison = 0;
						
			localUser.state = initialUserState;
			
			if (activeLocalUser && localUser.ID == initialActiveUserState.localUserID) {
				*activeLocalUser = localUser;
			}
		}
		
		NSAssert(!activeLocalUser || *activeLocalUser, @"Could not find initial active LocalUser");
	}
	
	
	
	[Database deleteMatchTurn:matchTurnToDelete];
}


#pragma mark - Helper

+ (NSMutableArray *)userStatesFromLocalUsers:(NSArray *)localUsers {
	NSMutableArray *userStates = [[NSMutableArray alloc] initWithCapacity:[localUsers count]];
	
	for (LocalUser *localUser in localUsers) {
		[userStates addObject:localUser.state];
	}
	
	return userStates;
}


@end
