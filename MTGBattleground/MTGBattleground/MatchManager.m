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
	match.defaultStartingLife = startingLife;
	match.enablePoisonCounter = poisonCounter;
	match.enableDynamicCounters = dynamicCounters;
	match.enableTurnTracking = turnTracking;
	match.startDate = [NSDate date];
	
	// persist Match
	[Database createMatch:match];
	
	// initialize users
	for (LocalUser *localUser in localUsers) {
		if (!localUser.state) {
			localUser.state = [[UserState alloc] init];
		}
		
		localUser.state.life = startingLife;
		localUser.state.poison = 0;
	}
	
	[Database createLocalUserActiveStates:localUsers forMatch:match];
	[Database createLocalUserParticipants:localUsers forMatch:match];
	
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
		[Database createLocalUserStates:allLocalUsers forMatchTurn:matchTurn];
	});
	
	return matchTurn;
}

+ (void)deleteActiveMatch:(Match *)match {
	dispatch_async([Database backgroundQueue], ^{
		[Database deleteMatch:match];
		[Database deleteLocalUserActiveStatesForMatch:match];
	});
}

+ (void)resetMatchToPreviousTurnState:(Match *)match localUsers:(NSArray *)localUsers {
	MatchTurn *matchTurn = [Database lastMatchTurnForMatch:match];
	
}

@end
