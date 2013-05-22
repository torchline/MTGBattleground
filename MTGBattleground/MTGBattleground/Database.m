//
//  Database.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Database.h"
#import "Match.h"
#import "MatchTurn.h"
#import "ResourceManager.h"
#import "Settings.h"
#import "LocalUser.h"
#import "UserIcon.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@implementation Database

#pragma mark - Init

static FMDatabaseQueue *_fmDatabaseQueue = nil;
+ (FMDatabaseQueue *)fmDatabaseQueue {
	if (!_fmDatabaseQueue) {
		NSString *bundleDBPath = [[NSBundle mainBundle] pathForResource:@"MTGBattleground" ofType:@"sqlite"];
		NSString *docDBPath = [[ResourceManager databaseDirectory] stringByAppendingPathComponent:@"MTGBattleground.sqlite"];
		
		NSError *error;
		[ResourceManager copyFileAtPathIfNewer:bundleDBPath toPath:docDBPath error:&error];
		if (error) {
			NSLog(@"%@", [error	localizedDescription]);
		}
		
		_fmDatabaseQueue = [[FMDatabaseQueue alloc] initWithPath:docDBPath];
	}
				
	return _fmDatabaseQueue;
}


#pragma mark - Cache

static NSMutableDictionary *_localUserCache = nil;
+ (void)addLocalUserToCache:(LocalUser *)localUser {
	if (!_localUserCache) {
		_localUserCache = [[NSMutableDictionary alloc] initWithCapacity:4];
	}
	
	[_localUserCache setObject:localUser forKey:@(localUser.ID)];
}

static NSMutableDictionary *_matchCache = nil;
+ (void)addMatchToCache:(Match *)match {
	if (!_matchCache) {
		_matchCache = [[NSMutableDictionary alloc] initWithCapacity:4];
	}
	
	[_matchCache setObject:match forKey:match.ID];
}

static NSMutableDictionary *_matchTurnCache = nil;
+ (void)addMatchTurnToCache:(MatchTurn *)matchTurn {
	if (!_matchTurnCache) {
		_matchTurnCache = [[NSMutableDictionary alloc] initWithCapacity:4];
	}
	
	[_matchTurnCache setObject:matchTurn forKey:matchTurn.ID];
}


#pragma mark - CREATE

#pragma mark Match

+ (void)createMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"INSERT INTO Match (ID, WinnerLocalUserID, StartingLife, PoisonToDie, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, EnableAutoDeath, IsComplete, StartDate, EndDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[
						match.ID,
						match.winnerLocalUserID > 0 ? @(match.winnerLocalUserID) : [NSNull null],
						@(match.startingLife),
						@(match.poisonToDie),
						@(match.enablePoisonCounter),
						@(match.enableDynamicCounters),
						@(match.enableTurnTracking),
						@(match.enableAutoDeath),
						@(match.isComplete),
						@((unsigned long)[match.startDate timeIntervalSince1970]),
						match.endDate ? @((unsigned long)[match.endDate timeIntervalSince1970]) : [NSNull null]
						]];
		
		NSAssert(success, @"failed creating Match: %@", [db lastErrorMessage]);
		
		[self addMatchToCache:match];
	}];
}

+ (void)createInitialUserStates:(NSArray *)userStates forMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSUInteger i = 0;
		for (UserState *userState in userStates) {
			BOOL success = [db executeUpdate:@"INSERT INTO Match_LocalUser_initialUserState (MatchID, LocalUserID, Ordinal, UserSlot, Life, Poison, IsDead) VALUES (?, ?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[
							match.ID,
							@(userState.localUserID),
							@(i),
							@(userState.userSlot),
							@(userState.life),
							@(userState.poison),
							@(userState.isDead),
							]];
			
			NSAssert(success, @"failed creating initial UserStates for Match: %@", [db lastErrorMessage]);
			
			i++;
		}
	}];
}

+ (void)createCurrentUserStates:(NSArray *)userStates forMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		for (UserState *userState in userStates) {
			BOOL success = [db executeUpdate:@"INSERT INTO Match_LocalUser_currentUserState (MatchID, LocalUserID, UserSlot, Life, Poison, IsDead) VALUES (?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[
							match.ID,
							@(userState.localUserID),
							@(userState.userSlot),
							@(userState.life),
							@(userState.poison),
							@(userState.isDead),
							]];
			
			NSAssert(success, @"failed creating current UserStates for Match: %@", [db lastErrorMessage]);
		}
	}];
}

+ (void)createFinalUserStates:(NSArray *)userStates forMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		for (UserState *userState in userStates) {
			BOOL success = [db executeUpdate:@"INSERT INTO Match_LocalUser_finalUserState (MatchID, LocalUserID, UserSlot, Life, Poison, IsDead) VALUES (?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[
							match.ID,
							@(userState.localUserID),
							@(userState.userSlot),
							@(userState.life),
							@(userState.poison),
							@(userState.isDead),
							]];
			
			NSAssert(success, @"failed creating final UserStates for Match: %@", [db lastErrorMessage]);
		}
	}];
}


#pragma mark MatchTurn

+ (void)createMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"INSERT INTO MatchTurn(ID, MatchID, LocalUserID, EndDate) VALUES(?, ?, ?, ?)" withArgumentsInArray:@[
						matchTurn.ID,
						matchTurn.matchID,
						@(matchTurn.localUserID),
						@((unsigned long)[matchTurn.endDate timeIntervalSince1970])
						]];
		
		NSAssert(success, @"failed creating MatchTurn: %@", [db lastErrorMessage]);
		
		[self addMatchTurnToCache:matchTurn];
	}];
}

+ (void)createUserStates:(NSArray *)userStates forMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		for (UserState *userState in userStates) {
			BOOL success = [db executeUpdate:@"INSERT INTO MatchTurn_LocalUser_userState(MatchTurnID, LocalUserID, UserSlot, Life, Poison, IsDead) VALUES(?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[
							matchTurn.ID,
							@(userState.localUserID),
							@(userState.userSlot),
							@(userState.life),
							@(userState.poison),
							@(userState.isDead),
							]];
			
			NSAssert(success, @"failed creating UserStates for MatchTurn: %@", [db lastErrorMessage]);
		}
	}];
}


#pragma mark - READ

#pragma mark Match

+ (Match *)matchWithID:(NSString *)ID {
	Match __block *match;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, WinnerLocalUserID, StartingLife, PoisonToDie, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, EnableAutoDeath, IsComplete, StartDate, EndDate FROM Match WHERE ID = ?" withArgumentsInArray:@[
								  ID
								  ]];
		
		if ([resultSet next]) {
			match = [self matchFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];
	
	return match;
}

+ (Match *)activeMatch {
	Match __block *match;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT ID, WinnerLocalUserID, StartingLife, PoisonToDie, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, EnableAutoDeath, IsComplete, StartDate, EndDate FROM Match WHERE ID = (SELECT Value FROM Settings WHERE Key='%@')", SETTINGS_CURRENT_ACTIVE_MATCH_ID];
		FMResultSet *resultSet = [db executeQuery:query];
		
		if ([resultSet next]) {
			match = [self matchFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];
	
	return match;
}

+ (NSMutableArray *)initialUserStatesForMatch:(Match *)match {
	NSMutableArray __block *userStates;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"SELECT LocalUserID, UserSlot, Life, Poison, IsDead FROM Match_LocalUser_initialUserState WHERE MatchID = ? ORDER BY Ordinal";
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  match.ID
								  ]];
		
		while ([resultSet next]) {
			if (!userStates) {
				userStates = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			UserState *userState = [self userStateFromResultSet:resultSet];
			
			[userStates addObject:userState];
		}
		
		[resultSet close];
	}];
	
	return userStates;
}


#pragma mark MatchTurn

+ (NSMutableArray *)matchTurnsForMatch:(Match *)match {
	NSMutableArray __block *matchTurns;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, MatchID, LocalUserID, EndDate FROM MatchTurn WHERE MatchID = ?" withArgumentsInArray:@[
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

+ (MatchTurn *)lastMatchTurnForMatch:(Match *)match {
	MatchTurn __block *matchTurn;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, MatchID, LocalUserID, EndDate FROM MatchTurn WHERE MatchID = ? ORDER BY EndDate DESC LIMIT 1" withArgumentsInArray:@[
								  match.ID
								  ]];
		
		if ([resultSet next]) {
			matchTurn = [self matchTurnFromResultSet:resultSet];			
		}
		
		[resultSet close];
	}];
	
	
	return matchTurn;
}

+ (MatchTurn *)secondToLastMatchTurnForMatch:(Match *)match {
	MatchTurn __block *matchTurn;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, MatchID, LocalUserID, EndDate FROM MatchTurn WHERE MatchID = ? ORDER BY EndDate DESC LIMIT 1 OFFSET 1" withArgumentsInArray:@[
								  match.ID
								  ]];
		
		if ([resultSet next]) {
			matchTurn = [self matchTurnFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];
	
	
	return matchTurn;
}


#pragma mark LocalUser

+ (NSMutableArray *)localUsersParticipatingInMatch:(Match *)match activeLocalUser:(LocalUser *__autoreleasing*)activeLocalUser {
	NSMutableArray __block *localUsers;
		
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *localUserResultSet = [db executeQuery:@"SELECT lu.ID, lu.Name, lu.UserIconID, lu.NumTimesUsed, lu.LastDateUsed, mlucs.LocalUserID, mlucs.UserSlot, mlucs.Life, mlucs.Poison, mlucs.isDead FROM LocalUser lu INNER JOIN Match_LocalUser_currentUserState mlucs ON lu.ID = mlucs.LocalUserID INNER JOIN Match_LocalUser_initialUserState mluis ON lu.ID = mluis.LocalUserID WHERE mluis.MatchID = ? AND mlucs.MatchID = ? ORDER BY mluis.Ordinal" withArgumentsInArray:@[
										   match.ID,
										   match.ID
										   ]];
		
		while ([localUserResultSet next]) {
			if (!localUsers) {
				localUsers = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			LocalUser *localUser = [self localUserWithUserStateFromResultSet:localUserResultSet];
			
			[localUsers addObject:localUser];
		}
		
		[localUserResultSet close];
	}];
	
	if (activeLocalUser) {
		MatchTurn *lastMatchTurn = [Database lastMatchTurnForMatch:match];
		
		if (lastMatchTurn) {
			BOOL activateNextLocalUser = NO;
			
			for (LocalUser *localUser in localUsers) {
				if (activateNextLocalUser) {
					*activeLocalUser = localUser;
					break;
				}
				else if (localUser.ID == lastMatchTurn.localUserID) {
					activateNextLocalUser = YES;
				}
			}
			
			if (!(*activeLocalUser)) {
				if (activateNextLocalUser) {
					*activeLocalUser = [localUsers objectAtIndex:0];
				}
			}
			
			NSAssert(*activeLocalUser, @"Could not find last active LocalUser in Match(%@)", match.ID);
		}
		else {
			*activeLocalUser = [localUsers objectAtIndex:0];
		}
	}
	
	return localUsers;
}

+ (NSMutableArray *)localUsers {
	NSMutableArray __block *localUsers;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, UserIconID, Name, NumTimesUsed, LastDateUsed FROM LocalUser"];
		
		while ([resultSet next]) {
			if (!localUsers) {
				localUsers = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			LocalUser *localUser = [self localUserFromResultSet:resultSet];
			
			[localUsers addObject:localUser];
		}
		
		[resultSet close];
	}];
	
	return localUsers;
}


#pragma mark UserState

+ (NSMutableArray *)userStatesForMatchTurn:(MatchTurn *)matchTurn {
	NSMutableArray __block *userStates;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT LocalUserID, UserSlot, Life, Poison, IsDead FROM MatchTurn_LocalUser_userState WHERE MatchTurnID = ?" withArgumentsInArray:@[
								  matchTurn.ID
								  ]];
		
		while ([resultSet next]) {
			if (!userStates) {
				userStates = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			UserState *userState = [self userStateFromResultSet:resultSet];
			
			[userStates addObject:userState];
		}
		
		[resultSet close];
	}];
	
	return userStates;
}


#pragma mark UserIcon

+ (NSMutableArray *)userIcons {
	NSMutableArray __block *userIcons;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, ImagePath FROM UserIcon"];
		
		while ([resultSet next]) {
			if (!userIcons) {
				userIcons = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			UserIcon *userIcon = [self userIconFromResultSet:resultSet];
			
			[userIcons addObject:userIcon];
		}
		
		[resultSet close];
	}];
	
	return userIcons;
}


#pragma mark - UPDATE

#pragma mark Match

+ (void)updateCurrentUserStateForActiveMatch:(UserState *)userState {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Match_LocalUser_currentUserState SET UserSlot = ?, Life = ?, Poison = ?, IsDead = ? WHERE LocalUserID = ? AND MatchID = (SELECT Value FROM Settings WHERE Key='%@')", SETTINGS_CURRENT_ACTIVE_MATCH_ID];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						@(userState.userSlot),
						@(userState.life),
						@(userState.poison),
						@(userState.isDead),
						@(userState.localUserID)
						]];
		
		NSAssert(success, @"failed updating LocalUser UserState: %@", [db lastErrorMessage]);
	}];
}


#pragma mark LocalUser

+ (void)updateLocalUser:(LocalUser *)localUser {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"UPDATE LocalUser SET Name = ?, UserIconID = ?, NumTimesUsed = ?, LastDateUsed = ? WHERE ID = ?" withArgumentsInArray:@[
						localUser.name,
						localUser.userIconID > 0 ? @(localUser.userIconID) : [NSNull null],
						@(localUser.numTimesUsed),
						@((unsigned long)[localUser.lastDateUsed timeIntervalSince1970]),
						@(localUser.ID)
						]];
		
		NSAssert(success, @"failed updating LocalUser: %@", [db lastErrorMessage]);
	}];
}


#pragma mark - DELETE

#pragma mark Match

+ (void)deleteMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"DELETE FROM Match WHERE ID = ?" withArgumentsInArray:@[
						match.ID
						]];
		
		NSAssert(success, @"failed deleting Match: %@", [db lastErrorMessage]);
	}];
}

+ (void)deleteCurrentUserStatesForMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"DELETE FROM Match_LocalUser_currentUserState WHERE MatchID = ?" withArgumentsInArray:@[
						match.ID
						]];
		
		NSAssert(success, @"failed deleting current UserStates for Match: %@", [db lastErrorMessage]);
	}];
}


#pragma mark MatchTurn

+ (void)deleteMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"DELETE FROM MatchTurn WHERE ID = ?" withArgumentsInArray:@[
						matchTurn.ID
						]];
		
		NSAssert(success, @"failed deleting MatchTurn: %@", [db lastErrorMessage]);
	}];
}


#pragma mark - Object Builders

+ (LocalUser *)localUserFromResultSet:(FMResultSet *)resultSet {
	LocalUser *localUser = [[LocalUser alloc] init];
	
	localUser.ID = [resultSet intForColumn:@"ID"];
	localUser.name = [resultSet stringForColumn:@"Name"];
	localUser.userIconID = [resultSet intForColumn:@"UserIconID"];
	localUser.numTimesUsed = [resultSet intForColumn:@"NumTimesUsed"];
	localUser.lastDateUsed = [[NSDate alloc] initWithTimeIntervalSince1970:[resultSet intForColumn:@"LastDateUsed"]];
	
	return localUser;
}

+ (LocalUser *)localUserWithUserStateFromResultSet:(FMResultSet *)resultSet {
	LocalUser *localUser = [[LocalUser alloc] init];
	
	localUser.ID = [resultSet intForColumn:@"ID"];
	localUser.name = [resultSet stringForColumn:@"Name"];
	localUser.userIconID = [resultSet intForColumn:@"UserIconID"];
	localUser.numTimesUsed = [resultSet intForColumn:@"NumTimesUsed"];
	localUser.lastDateUsed = [[NSDate alloc] initWithTimeIntervalSince1970:[resultSet intForColumn:@"LastDateUsed"]];
	
	localUser.state = [self userStateFromResultSet:resultSet];

	return localUser;
}

+ (UserState *)userStateFromResultSet:(FMResultSet *)resultSet {
	UserState *userState = [[UserState alloc] init];
	
	userState.localUserID = [resultSet intForColumn:@"LocalUserID"];
	userState.userSlot = [resultSet intForColumn:@"UserSlot"];
	userState.life = [resultSet intForColumn:@"Life"];
	userState.poison = [resultSet intForColumn:@"Poison"];
	userState.isDead = [resultSet boolForColumn:@"IsDead"];

	return userState;
}

+ (UserIcon *)userIconFromResultSet:(FMResultSet *)resultSet {
	UserIcon *userIcon = [[UserIcon alloc] init];
	
	userIcon.ID = [resultSet intForColumn:@"ID"];
	userIcon.imagePath = [resultSet stringForColumn:@"ImagePath"];
	
	return userIcon;
}

+ (Match *)matchFromResultSet:(FMResultSet *)resultSet {
	NSString *matchID = [resultSet stringForColumn:@"ID"];
	
	Match *cachedMatch = [_matchCache objectForKey:matchID];
	if (cachedMatch) {
		return cachedMatch;
	}
	
	Match *match = [[Match alloc] init];
	
	match.ID = matchID;
	match.winnerLocalUserID = [resultSet intForColumn:@"WinnerLocalUserID"];
	match.startingLife = [resultSet intForColumn:@"StartingLife"];
	match.poisonToDie = [resultSet intForColumn:@"PoisonToDie"];
	match.enablePoisonCounter = [resultSet boolForColumn:@"EnablePoisonCounter"];
	match.enableDynamicCounters = [resultSet boolForColumn:@"EnableDynamicCounters"];
	match.enableTurnTracking = [resultSet boolForColumn:@"EnableTurnTracking"];
	match.enableAutoDeath = [resultSet boolForColumn:@"EnableAutoDeath"];
	match.isComplete = [resultSet boolForColumn:@"IsComplete"];
	match.startDate = [resultSet dateForColumn:@"StartDate"];
	match.endDate = [resultSet dateForColumn:@"EndDate"];
	
	[self addMatchToCache:match];
	
	return match;
}

+ (MatchTurn *)matchTurnFromResultSet:(FMResultSet *)resultSet {
	NSString *matchTurnID = [resultSet stringForColumn:@"ID"];
	
	MatchTurn *cachedMatchTurn = [_matchCache objectForKey:matchTurnID];
	if (cachedMatchTurn) {
		return cachedMatchTurn;
	}
	
	MatchTurn *matchTurn = [[MatchTurn alloc] init];
	
	matchTurn.ID = matchTurnID;
	matchTurn.matchID = [resultSet stringForColumn:@"MatchID"];
	matchTurn.localUserID = [resultSet intForColumn:@"LocalUserID"];
	matchTurn.endDate = [resultSet dateForColumn:@"EndDate"];
	
	[self addMatchTurnToCache:matchTurn];
	
	return matchTurn;
}


#pragma mark - Misc

+ (NSString *)newGUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(__bridge NSString *)string stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

+ (NSMutableDictionary *)idDictionaryForDatabaseObjects:(NSArray *)dbObjects {
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[dbObjects count]];
	
	for (id <IdentifiableDatabaseObject> dbObject in dbObjects) {
		[dictionary setObject:dbObject forKey:[dbObject identifiableID]];
	}
	
	return dictionary;
}

static dispatch_queue_t _backgroundQueue = nil;
+ (dispatch_queue_t)backgroundQueue {
	if (!_backgroundQueue) {
		_backgroundQueue = dispatch_queue_create("com.torchlinetechnology.MTGBattleground.db", NULL);
	}
	
	return _backgroundQueue;
}


@end
