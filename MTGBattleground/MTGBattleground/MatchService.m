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
#import "MatchTurn+Runtime.h"
#import "MatchTurnUserState.h"
#import "MatchTurnUserDamage.h"


#define FIELDS_MATCH					@"ID, WinnerUserID, StartingLife, PoisonToDie, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, EnableAutoDeath, EnableDamageTargeting, IsComplete, StartTime, EndTime"
#define FIELDS_MATCH_USER_META			@"MatchID, UserID, TurnOrder, UserPosition"
#define FIELDS_MATCH_TURN				@"ID, MatchID, UserID, TurnNumber, PassTime"
#define FIELDS_MATCH_TURN_USER_STATE	@"MatchTurnID, UserID, Life, Poison, IsDead"
#define FIELDS_MATCH_TURN_USER_DAMAGE	@"MatchTurnID, UserID, DamagedUserID, LifeDamage, PoisonDamage"


@implementation MatchService

#pragma mark - Object Builders

+ (Match *)matchFromResultSet:(FMResultSet *)resultSet {
	Match *match;
	
	NSString *matchID = [resultSet stringForColumn:@"ID"];
	
	Match *cachedMatch = [self matchFromCacheWithID:matchID];
	if (cachedMatch) {
		match = cachedMatch;
	}
	else {
		match = [[Match alloc] initWithID:matchID
							 winnerUserID:[resultSet stringForColumn:@"WinnerUserID"]
							 startingLife:[resultSet intForColumn:@"StartingLife"]
							  poisonToDie:[resultSet intForColumn:@"PoisonToDie"]
							poisonCounter:[resultSet boolForColumn:@"EnablePoisonCounter"]
						  dynamicCounters:[resultSet boolForColumn:@"EnableDynamicCounters"]
							 turnTracking:[resultSet boolForColumn:@"EnableTurnTracking"]
								autoDeath:[resultSet boolForColumn:@"EnableAutoDeath"]
						  damageTargeting:[resultSet boolForColumn:@"EnableDamageTargeting"]
								 complete:[resultSet boolForColumn:@"IsComplete"]
								startTime:[resultSet dateForColumn:@"StartTime"]
								  endTime:[resultSet dateForColumn:@"EndTime"]];
		
		[self cacheMatch:match];
	}
	
	return match;
}

+ (MatchUserMeta *)matchUserMetaFromResultSet:(FMResultSet *)resultSet {
	MatchUserMeta *matchUserMeta;
	
	NSString *matchID = [resultSet stringForColumn:@"MatchID"];
	NSString *userID = [resultSet stringForColumn:@"UserID"];

	MatchUserMeta *cachedMatchUserMeta = [self matchUserMetaFromCacheWithMatchID:matchID userID:userID];
	if (cachedMatchUserMeta) {
		matchUserMeta = cachedMatchUserMeta;
	}
	else {
		matchUserMeta = [[MatchUserMeta alloc] initWithMatchID:matchID
														userID:userID
													 turnOrder:[resultSet intForColumn:@"TurnOrder"]
												  userPosition:[resultSet intForColumn:@"UserPosition"]];
		
		[self cacheMatchUserMeta:matchUserMeta];
	}
	
	return matchUserMeta;
}

+ (MatchTurn *)matchTurnFromResultSet:(FMResultSet *)resultSet {
	MatchTurn *matchTurn;
	
	NSString *matchTurnID = [resultSet stringForColumn:@"ID"];
	
	MatchTurn *cachedMatchTurn = [self matchTurnFromCacheWithID:matchTurnID];
	if (cachedMatchTurn) {
		matchTurn = cachedMatchTurn;
	}
	else {
		matchTurn = [[MatchTurn alloc] initWithID:matchTurnID
										  matchID:[resultSet stringForColumn:@"MatchID"]
										   userID:[resultSet stringForColumn:@"UserID"]
									   turnNumber:[resultSet intForColumn:@"TurnNumber"]
										 passTime:[resultSet dateForColumn:@"PassTime"]];
		
		[self cacheMatchTurn:matchTurn];
	}
	
	return matchTurn;
}

+ (MatchTurnUserState *)matchTurnUserStateFromResultSet:(FMResultSet *)resultSet {
	MatchTurnUserState *matchTurnUserState;
	
	NSString *matchTurnID = [resultSet stringForColumn:@"MatchTurnID"];
	NSString *userID = [resultSet stringForColumn:@"UserID"];
	
	MatchTurnUserState *cachedMatchTurnUserState = [self matchTurnUserStateFromCacheWithMatchTurnID:matchTurnID userID:userID];
	if (cachedMatchTurnUserState) {
		matchTurnUserState = cachedMatchTurnUserState;
	}
	else {
		matchTurnUserState = [[MatchTurnUserState alloc] initWithMatchTurnID:matchTurnID
																	  userID:userID
																		life:[resultSet intForColumn:@"Life"]
																	  poison:[resultSet intForColumn:@"Poison"]
																	  isDead:[resultSet boolForColumn:@"IsDead"]];
		
		[self cacheMatchTurnUserState:matchTurnUserState];
	}
	
	return matchTurnUserState;
}

+ (MatchTurnUserDamage *)matchTurnUserDamageFromResultSet:(FMResultSet *)resultSet {
	MatchTurnUserDamage *matchTurnUserDamage;
	
	NSString *matchTurnID = [resultSet stringForColumn:@"MatchTurnID"];
	NSString *userID = [resultSet stringForColumn:@"UserID"];
	
	MatchTurnUserDamage *cachedMatchTurnUserDamage = [self matchTurnUserDamageFromCacheWithMatchTurnID:matchTurnID userID:userID];
	if (cachedMatchTurnUserDamage) {
		matchTurnUserDamage = cachedMatchTurnUserDamage;
	}
	else {
		matchTurnUserDamage = [[MatchTurnUserDamage alloc] initWithMatchTurnID:matchTurnID
																		userID:userID
																 damagedUserID:[resultSet stringForColumn:@"DamagedUserID"]
																	lifeDamage:[resultSet intForColumn:@"LifeDamage"]
																  poisonDamage:[resultSet intForColumn:@"PoisonDamage"]];
		
		[self cacheMatchTurnUserDamage:matchTurnUserDamage];
	}
	
	return matchTurnUserDamage;
}


#pragma mark - Cache

static NSCache *_matchCache = nil;
+ (Match *)matchFromCacheWithID:(NSString *)matchID {
	return [_matchCache objectForKey:matchID];
}
+ (void)cacheMatch:(Match *)match {
	if (!_matchCache) {
		_matchCache = [NSCache new];
	}
	
	[_matchCache setObject:match forKey:match.ID];
}

static NSCache *_matchUserMetaCache = nil;
+ (MatchUserMeta *)matchUserMetaFromCacheWithMatchID:(NSString *)matchID userID:(NSString *)userID {
	return [_matchUserMetaCache objectForKey:[[NSString alloc] initWithFormat:@"%@-%@", matchID, userID]];
}
+ (void)cacheMatchUserMeta:(MatchUserMeta *)matchUserMeta {
	if (!_matchUserMetaCache) {
		_matchUserMetaCache = [NSCache new];
	}
	
	[_matchUserMetaCache setObject:matchUserMeta forKey:[[NSString alloc] initWithFormat:@"%@-%@", matchUserMeta.matchID, matchUserMeta.userID]];
}

static NSCache *_matchTurnCache = nil;
+ (MatchTurn *)matchTurnFromCacheWithID:(NSString *)matchTurnID {
	return [_matchTurnCache objectForKey:matchTurnID];
}
+ (void)cacheMatchTurn:(MatchTurn *)matchTurn {
	if (!_matchTurnCache) {
		_matchTurnCache = [NSCache new];
	}
	
	[_matchTurnCache setObject:matchTurn forKey:matchTurn.ID];
}

static NSCache *_matchTurnUserStateCache = nil;
+ (MatchTurnUserState *)matchTurnUserStateFromCacheWithMatchTurnID:(NSString *)matchTurnID userID:(NSString *)userID {
	return [_matchTurnUserStateCache objectForKey:[[NSString alloc] initWithFormat:@"%@-%@", matchTurnID, userID]];
}
+ (void)cacheMatchTurnUserState:(MatchTurnUserState *)matchTurnUserState {
	if (!_matchTurnUserStateCache) {
		_matchTurnUserStateCache = [NSCache new];
	}
	
	[_matchTurnUserStateCache setObject:matchTurnUserState forKey:[[NSString alloc] initWithFormat:@"%@-%@", matchTurnUserState.matchTurnID, matchTurnUserState.userID]];
}

static NSCache *_matchTurnUserDamageCache = nil;
+ (MatchTurnUserDamage *)matchTurnUserDamageFromCacheWithMatchTurnID:(NSString *)matchTurnID userID:(NSString *)userID {
	return [_matchTurnUserDamageCache objectForKey:[[NSString alloc] initWithFormat:@"%@-%@", matchTurnID, userID]];
}
+ (void)cacheMatchTurnUserDamage:(MatchTurnUserDamage *)matchTurnUserDamage {
	if (!_matchTurnUserDamageCache) {
		_matchTurnUserDamageCache = [NSCache new];
	}
	
	[_matchTurnUserDamageCache setObject:matchTurnUserDamage forKey:[[NSString alloc] initWithFormat:@"%@-%@", matchTurnUserDamage.matchTurnID, matchTurnUserDamage.userID]];
}


#pragma mark - Match

+ (NSUInteger)numberOfMatches {
	NSUInteger __block numberOfMatches = 0;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"SELECT COUNT(1) AS Count FROM Match";
		FMResultSet *resultSet = [db executeQuery:query];
		
		NSAssert([resultSet next], @"%@", [db lastErrorMessage]);
		
		numberOfMatches = [resultSet intForColumn:@"Count"];
		
		[resultSet close];
	}];
	
	return numberOfMatches;
}

+ (NSMutableArray *)matchesWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
	NSMutableArray __block *matches;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM Match LIMIT ? OFFSET ?", FIELDS_MATCH];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  @(limit),
								  @(offset)
								  ]];
		
		while ([resultSet next]) {
			if (!matches) {
				matches = [[NSMutableArray alloc] initWithCapacity:30];
			}
			
			Match *match = [self matchFromResultSet:resultSet];
			
			[matches addObject:match];
		}
		
		[resultSet close];
	}];
	
	return matches;
}

+ (Match *)matchWithID:(NSString *)matchID {
	Match __block *match;
	
	Match *cachedMatch = [self matchFromCacheWithID:matchID];
	if (cachedMatch) {
		match = cachedMatch;
	}
	else {
		[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
			NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM Match WHERE ID = ? LIMIT 1", FIELDS_MATCH];
			FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
									  matchID
									  ]];
			
			NSAssert([resultSet next], @"%@", [db lastErrorMessage]);
			
			match = [self matchFromResultSet:resultSet];
			
			[resultSet close];
		}];
	}
	
	return match;
}

+ (void)insertMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Match (%@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", FIELDS_MATCH];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						match.ID,
						match.winnerUserID ? match.winnerUserID : [NSNull null],
						@(match.startingLife),
						@(match.poisonToDie),
						@(match.enablePoisonCounter),
						@(match.enableDynamicCounters),
						@(match.enableTurnTracking),
						@(match.enableAutoDeath),
						@(match.enableDamageTargeting),
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
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM Match_User_meta WHERE MatchID = ? ORDER BY TurnOrder", FIELDS_MATCH_USER_META];
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
		latestMatchTurn.match = match;
		
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


#pragma mark - MatchTurnUserDamage

+ (NSMutableArray *)matchTurnUserDamagesForMatchTurn:(MatchTurn *)matchTurn {
	NSMutableArray __block *userStates;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM MatchTurn_User_damage WHERE MatchTurnID = ?", FIELDS_MATCH_TURN_USER_DAMAGE];
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  matchTurn.ID
								  ]];
		
		while ([resultSet next]) {
			if (!userStates) {
				userStates = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			MatchTurnUserDamage *userDamage = [self matchTurnUserDamageFromResultSet:resultSet];
			
			[userStates addObject:userDamage];
		}
		
		[resultSet close];
	}];
	
	return userStates;
}

+ (void)insertMatchTurnUserDamage:(MatchTurnUserDamage *)userDamage {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO MatchTurn_User_damage (%@) VALUES (?, ?, ?, ?, ?)", FIELDS_MATCH_TURN_USER_DAMAGE];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						userDamage.matchTurnID,
						userDamage.userID,
						userDamage.damagedUserID,
						@(userDamage.lifeDamage),
						@(userDamage.poisonDamage)
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
}

@end
