//
//  MatchService.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchService.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "Match.h"
#import "MatchUserMeta.h"
#import "MatchTurn.h"
#import "MatchTurnUserState.h"


#define FIELDS_MATCH					@"ID, WinnerUserID, StartingLife, PoisonToDie, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, EnableAutoDeath, IsComplete, StartTime, EndTime"
#define FIELDS_MATCH_USER_META			@"MatchID, UserID, TurnOrder, UserPosition"
#define FIELDS_MATCH_TURN				@"ID, MatchID, UserID, TurnNumber, PassTime"
#define FIELDS_MATCH_TURN_USER_STATE	@"MatchTurnID, UserID, Life, Poison, IsDead"


@implementation MatchService

#pragma mark - Object Builders

+ (Match *)matchFromResultSet:(FMResultSet *)resultSet {
	return [[Match alloc] initWithID:[resultSet stringForColumn:@"ID"]
						winnerUserID:[resultSet stringForColumn:@"WinnerUserID"]
						startingLife:[resultSet intForColumn:@"StartingLife"]
						 poisonToDie:[resultSet intForColumn:@"PoisonToDie"]
					   poisonCounter:[resultSet boolForColumn:@"EnablePoisonCounter"]
					 dynamicCounters:[resultSet boolForColumn:@"EnableDynamicCounters"]
						turnTracking:[resultSet boolForColumn:@"EnableTurnTracking"]
						   autoDeath:[resultSet boolForColumn:@"EnableAutoDeath"]
							complete:[resultSet boolForColumn:@"IsComplete"]
						   startTime:[resultSet dateForColumn:@"StartTime"]
							 endTime:[resultSet dateForColumn:@"EndTime"]];
}

+ (MatchUserMeta *)matchUserMetaFromResultSet:(FMResultSet *)resultSet {
	return [[MatchUserMeta alloc] initWithMatchID:[resultSet stringForColumn:@"MatchID"]
										   userID:[resultSet stringForColumn:@"UserID"]
										turnOrder:[resultSet intForColumn:@"TurnOrder"]
									 userPosition:[resultSet intForColumn:@"UserPosition"]];
}

+ (MatchTurn *)matchTurnFromResultSet:(FMResultSet *)resultSet {
	return [[MatchTurn alloc] initWithID:[resultSet stringForColumn:@"ID"]
								 matchID:[resultSet stringForColumn:@"MatchID"]
								  userID:[resultSet stringForColumn:@"UserID"]
							  turnNumber:[resultSet intForColumn:@"TurnNumber"]
								passTime:[resultSet dateForColumn:@"PassTime"]];
}

+ (MatchTurnUserState *)matchTurnUserStateFromResultSet:(FMResultSet *)resultSet {
	return [[MatchTurnUserState alloc] initWithMatchTurnID:[resultSet stringForColumn:@"MatchTurnID"]
													userID:[resultSet stringForColumn:@"UserID"]
													  life:[resultSet intForColumn:@"Life"]
													poison:[resultSet intForColumn:@"Poison"]
													isDead:[resultSet boolForColumn:@"IsDead"]];
}


#pragma mark - Match

+ (Match *)matchWithID:(NSString *)matchID {
	Match __block *match;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM Match WHERE ID = ? LIMIT 1", FIELDS_MATCH];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  matchID
								  ]];
		
		NSAssert([resultSet next], @"%@", [db lastErrorMessage]);
		
		match = [self matchFromResultSet:resultSet];
		
		[resultSet close];
	}];
	
	return match;
}

+ (void)insertMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Match (%@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", FIELDS_MATCH];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						match.ID,
						match.winnerUserID ? match.winnerUserID : [NSNull null],
						@(match.startingLife),
						@(match.poisonToDie),
						@(match.enablePoisonCounter),
						@(match.enableDynamicCounters),
						@(match.enableTurnTracking),
						@(match.enableAutoDeath),
						@(match.isComplete),
						match.startTime ? match.startTime : [NSNull null],
						match.endTime ? match.endTime : [NSNull null]
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

+ (void)updateMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"UPDATE Match SET WinnerUserID = ?, IsComplete = ?, StartTime = ?, EndTime = ? WHERE ID = ?";
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						match.winnerUserID ? match.winnerUserID : [NSNull null],
						@(match.isComplete),
						match.startTime ? match.startTime : [NSNull null],
						match.endTime ? match.endTime : [NSNull null],
						
						match.ID,
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

+ (void)deleteMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"DELETE FROM Match WHERE ID = ?" withArgumentsInArray:@[
						match.ID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}


#pragma mark - MatchUserMeta

+ (NSMutableArray *)matchUserMetasForMatch:(Match *)match {
	NSMutableArray __block *matchUserMetas;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM Match_User_meta WHERE MatchID = ?", FIELDS_MATCH_TURN];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  match.ID
								  ]];
		
		while ([resultSet next]) {
			if (!matchUserMetas) {
				matchUserMetas = [[NSMutableArray alloc] initWithCapacity:30];
			}
			
			MatchUserMeta *matchUserMeta = [self matchUserMetaFromResultSet:resultSet];
			
			[matchUserMetas addObject:matchUserMeta];
		}
		
		[resultSet close];
	}];
	
	return matchUserMetas;
}

+ (void)insertMatchUserMeta:(MatchUserMeta *)meta {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Match_User_meta (%@) VALUES (?, ?, ?, ?)", FIELDS_MATCH_USER_META];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						meta.matchID,
						meta.userID,
						@(meta.turnOrder),
						@(meta.userPosition)
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}


#pragma mark - MatchTurn

+ (NSMutableArray *)matchTurnsForMatch:(Match *)match {
	NSMutableArray __block *matchTurns;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn WHERE MatchID = ?", FIELDS_MATCH_TURN];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  match.ID
								  ]];
		
		while ([resultSet next]) {
			if (!matchTurns) {
				matchTurns = [[NSMutableArray alloc] initWithCapacity:30];
			}
			
			MatchTurn *matchTurn = [self matchTurnFromResultSet:resultSet];
			
			[matchTurns addObject:matchTurn];
		}
		
		[resultSet close];
	}];
	
	return matchTurns;
}

+ (MatchTurn *)matchTurnPreviousToMatchTurn:(MatchTurn *)matchTurn {
	if (matchTurn.turnNumber == 0) {
		return nil;
	}
	
	MatchTurn __block *previousMatchTurn;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn WHERE MatchID = ? AND TurnNumber = ? LIMIT 1", FIELDS_MATCH_TURN];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  matchTurn.matchID,
								  @(matchTurn.turnNumber - 1)
								  ]];
		
		NSAssert([resultSet next], @"%@", [db lastErrorMessage]);
		
		previousMatchTurn = [self matchTurnFromResultSet:resultSet];
		
		[resultSet close];
	}];
	
	return previousMatchTurn;
}

+ (MatchTurn *)latestMatchTurnForMatch:(Match *)match offset:(NSUInteger)offset {
	MatchTurn __block *latestMatchTurn;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn WHERE MatchID = ? ORDER BY TurnNumber DESC LIMIT 1 OFFSET ?", FIELDS_MATCH_TURN];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  match.ID,
								  @(offset)
								  ]];
		
		NSAssert([resultSet next], @"%@", [db lastErrorMessage]);
		
		latestMatchTurn = [self matchTurnFromResultSet:resultSet];
		
		[resultSet close];
	}];
	
	return latestMatchTurn;
}

+ (void)insertMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO MatchTurn (%@) VALUES (?, ?, ?, ?, ?)", FIELDS_MATCH_TURN];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						matchTurn.ID,
						matchTurn.matchID,
						matchTurn.userID ? matchTurn.userID : [NSNull null],
						@(matchTurn.turnNumber),
						matchTurn.passTime ? matchTurn.passTime : [NSNull null]
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

+ (void)updateMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"UPDATE MatchTurn SET PassTime = ? WHERE ID = ?";
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						matchTurn.passTime ? matchTurn.passTime : [NSNull null],
						
						matchTurn.ID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

+ (void)deleteMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"DELETE FROM MatchTurn WHERE ID = ?" withArgumentsInArray:@[
						matchTurn.ID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}


#pragma mark MatchTurnUserState

+ (NSMutableArray *)matchTurnUserStatesForMatchTurn:(MatchTurn *)matchTurn {
	NSMutableArray __block *userStates;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn_User_state WHERE MatchTurnID = ?", FIELDS_MATCH_TURN_USER_STATE];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  matchTurn.ID
								  ]];
		
		while ([resultSet next]) {
			if (!userStates) {
				userStates = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			MatchTurnUserState *userState = [self matchTurnUserStateFromResultSet:resultSet];
			
			[userStates addObject:userState];
		}
		
		[resultSet close];
	}];
	
	return userStates;
}

+ (NSMutableDictionary *)matchTurnUserStateDictionaryForMatchTurn:(MatchTurn *)matchTurn {
	NSMutableDictionary __block *userStateDictionary;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn_User_state WHERE MatchTurnID = ?", FIELDS_MATCH_TURN_USER_STATE];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  matchTurn.ID
								  ]];
		
		while ([resultSet next]) {
			if (!userStateDictionary) {
				userStateDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
			}
			
			MatchTurnUserState *userState = [self matchTurnUserStateFromResultSet:resultSet];
			
			[userStateDictionary setObject:userState forKey:userState.userID];
		}
		
		[resultSet close];
	}];
	
	return userStateDictionary;
}

+ (void)insertMatchTurnUserState:(MatchTurnUserState *)userState {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO MatchTurn_User_state (%@) VALUES (?, ?, ?, ?, ?)", FIELDS_MATCH_TURN_USER_STATE];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						userState.matchTurnID,
						userState.userID,
						@(userState.life),
						@(userState.poison),
						@(userState.isDead)
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

+ (void)updateMatchTurnUserState:(MatchTurnUserState *)userState {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE MatchTurn_User_state SET Life = ?, Poison = ?, IsDead = ? WHERE MatchTurnID = ? AND UserID = ?"];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						@(userState.life),
						@(userState.poison),
						@(userState.isDead),
						
						userState.matchTurnID,
						userState.userID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

@end
