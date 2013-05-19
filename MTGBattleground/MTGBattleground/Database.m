//
//  Database.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Database.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Match.h"
#import "MatchTurn.h"
#import "ResourceManager.h"
#import "Settings.h"
#import "LocalUser.h"
#import "UserIcon.h"

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
		BOOL success = [db executeUpdate:@"INSERT INTO Match(ID, DefaultStartingLife, StartDate, EndDate) VALUES(?, ?, ?, ?)" withArgumentsInArray:@[
						[match.ID dataUsingEncoding:NSUTF8StringEncoding],
						@(match.defaultStartingLife),
						@([match.startDate timeIntervalSince1970]),
						@([match.endDate timeIntervalSince1970])
						]];
		
		if (success) {
			[self addMatchToCache:match];
		}
	}];
}

+ (void)createLocalUserParticipants:(NSArray *)localUsers forMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSUInteger i = 0;
		for (LocalUser *localUser in localUsers) {
			[db executeUpdate:@"INSERT INTO Match_LocalUser_participant(MatchID, LocalUserID, StartingLife, Ordinal) VALUES(?, ?, ?, ?)" withArgumentsInArray:@[
			 [match.ID dataUsingEncoding:NSUTF8StringEncoding],
			 @(localUser.ID),
			 @(localUser.state.life),
			 @(i)
			 ]];
			
			i++;
		}
	}];
}


#pragma mark MatchTurn

+ (void)createMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		BOOL success = [db executeUpdate:@"INSERT INTO MatchTurn(ID, MatchID, LocalUserID, EndDate) VALUES(?, ?, ?, ?)" withArgumentsInArray:@[
						[matchTurn.ID dataUsingEncoding:NSUTF8StringEncoding],
						[matchTurn.matchID dataUsingEncoding:NSUTF8StringEncoding],
						@(matchTurn.localUserID),
						@([matchTurn.endDate timeIntervalSince1970])
						]];
		
		if (success) {
			[self addMatchTurnToCache:matchTurn];
		}
	}];
}

+ (void)createLocalUserStates:(NSArray *)localUsers forMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		for (LocalUser *localUser in localUsers) {
			[db executeUpdate:@"INSERT INTO MatchTurn_LocalUser_state(MatchTurnID, LocalUserID, Life, Poison) VALUES(?, ?, ?, ?)" withArgumentsInArray:@[
			 [matchTurn.ID dataUsingEncoding:NSUTF8StringEncoding],
			 @(localUser.ID),
			 @(localUser.state.life),
			 @(localUser.state.poison)
			 ]];
		}
	}];
}


#pragma mark LocalUser

+ (void)createLocalUserActiveStates:(NSArray *)localUsers forMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		for (LocalUser *localUser in localUsers) {
			[db executeUpdate:@"INSERT INTO LocalUser_active (LocalUserID, MatchID, Life, Poison, UserSlot) VALUES (?, ?, ?, ?, ?)" withArgumentsInArray:@[
			 @(localUser.ID),
			 [match.ID dataUsingEncoding:NSUTF8StringEncoding],
			 @(localUser.state.life),
			 @(localUser.state.poison),
			 @(localUser.userSlot)
			 ]];			
		}
	}];
}



#pragma mark - READ

#pragma mark Match

+ (NSMutableArray *)matches {
	NSMutableArray __block *matches;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, DefaultStartingLife, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, StartDate, EndDate FROM Match"];
		
		while ([resultSet next]) {
			if (!matches) {
				matches = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			Match *match = [self matchFromResultSet:resultSet];

			[matches addObject:match];
		}
		
		[resultSet close];
	}];
	
	return matches;
}

+ (Match *)matchWithID:(NSString *)ID {
	Match __block *match;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, DefaultStartingLife, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, StartDate, EndDate FROM Match WHERE ID = ?" withArgumentsInArray:@[
								  [ID dataUsingEncoding:NSUTF8StringEncoding]
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
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT ID, DefaultStartingLife, EnablePoisonCounter, EnableDynamicCounters, EnableTurnTracking, StartDate, EndDate FROM Match WHERE ID = (SELECT Value FROM Settings WHERE Key='%@')", SETTINGS_CURRENT_ACTIVE_MATCH_ID];
		FMResultSet *resultSet = [db executeQuery:query];
		
		if ([resultSet next]) {
			match = [self matchFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];
	
	return match;
}


#pragma mark MatchTurn

+ (NSMutableArray *)matchTurnsForMatch:(Match *)match {
	NSMutableArray __block *matchTurns;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT ID, MatchID, LocalUserID, EndDate FROM MatchTurn WHERE MatchID = ?" withArgumentsInArray:@[
								  [match.ID dataUsingEncoding:NSUTF8StringEncoding]
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
								  [match.ID dataUsingEncoding:NSUTF8StringEncoding]
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
		NSData *matchIDData = [match.ID dataUsingEncoding:NSUTF8StringEncoding];
		FMResultSet *localUserResultSet = [db executeQuery:@"SELECT lu.ID, lu.Name, lu.UserIconID, lu.NumTimesUsed, lu.LastDateUsed, lua.Life, lua.Poison, lua.UserSlot FROM LocalUser lu INNER JOIN LocalUser_active lua ON lu.ID = lua.LocalUserID INNER JOIN Match_LocalUser_participant mup ON lu.ID = mup.LocalUserID WHERE mup.MatchID = ? AND lua.MatchID = ? ORDER BY mup.Ordinal" withArgumentsInArray:@[
										   matchIDData,
										   matchIDData
										   ]];
		
		while ([localUserResultSet next]) {
			if (!localUsers) {
				localUsers = [[NSMutableArray alloc] initWithCapacity:4];
			}
			
			LocalUser *localUser = [self localUserWithActiveStateFromResultSet:localUserResultSet];
			
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

#pragma mark LocalUser

+ (void)updateLocalUser:(LocalUser *)localUser {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		[db executeUpdate:@"UPDATE LocalUser SET Name = ?, UserIconID = ?, NumTimesUsed = ?, LastDateUsed = ? WHERE ID = ?" withArgumentsInArray:@[
		 localUser.name,
		 @(localUser.userIconID),
		 @(localUser.numTimesUsed),
		 @([localUser.lastDateUsed timeIntervalSince1970]),
		 @(localUser.ID)
		 ]];
	}];
}

+ (void)updateLocalUserUserState:(LocalUser *)localUser {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		[db executeUpdate:@"UPDATE LocalUser_active SET Life = ?, Poison = ? WHERE LocalUserID = ?" withArgumentsInArray:@[
		 @(localUser.state.life),
		 @(localUser.state.poison),
		 @(localUser.ID)
		 ]];
	}];
}

#pragma mark - DELETE

#pragma mark Match

+ (void)deleteMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		[db executeUpdate:@"DELETE FROM Match WHERE ID = ?" withArgumentsInArray:@[
		 [match.ID dataUsingEncoding:NSUTF8StringEncoding]
		 ]];
	}];
}


#pragma mark MatchTurn

+ (void)deleteMatchTurn:(MatchTurn *)matchTurn {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		[db executeUpdate:@"DELETE FROM MatchTurn WHERE ID = ?" withArgumentsInArray:@[
		 [matchTurn.ID dataUsingEncoding:NSUTF8StringEncoding]
		 ]];
	}];
}


#pragma mark LocalUser-ActiveState

+ (void)deleteLocalUserActiveStatesForMatch:(Match *)match {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		[db executeUpdate:@"DELETE FROM LocalUser_active WHERE MatchID = ?" withArgumentsInArray:@[
		 [match.ID dataUsingEncoding:NSUTF8StringEncoding]
		 ]];
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

+ (LocalUser *)localUserWithActiveStateFromResultSet:(FMResultSet *)resultSet {
	LocalUser *localUser = [[LocalUser alloc] init];
	
	localUser.ID = [resultSet intForColumn:@"ID"];
	localUser.name = [resultSet stringForColumn:@"Name"];
	localUser.userIconID = [resultSet intForColumn:@"UserIconID"];
	localUser.numTimesUsed = [resultSet intForColumn:@"NumTimesUsed"];
	localUser.lastDateUsed = [[NSDate alloc] initWithTimeIntervalSince1970:[resultSet intForColumn:@"LastDateUsed"]];
	localUser.userSlot = [resultSet intForColumn:@"UserSlot"];
	
	UserState *userState = [[UserState alloc] init];
	userState.life = [resultSet intForColumn:@"Life"];
	userState.poison = [resultSet intForColumn:@"Poison"];
	
	localUser.state = userState;

	return localUser;
}

+ (UserIcon *)userIconFromResultSet:(FMResultSet *)resultSet {
	UserIcon *userIcon = [[UserIcon alloc] init];
	
	userIcon.ID = [resultSet intForColumn:@"ID"];
	userIcon.imagePath = [resultSet stringForColumn:@"ImagePath"];
	
	return userIcon;
}

+ (Match *)matchFromResultSet:(FMResultSet *)resultSet {
	NSString *matchID = [[NSString alloc] initWithData:[resultSet dataForColumn:@"ID"] encoding:NSUTF8StringEncoding];
	
	Match *cachedMatch = [_matchCache objectForKey:matchID];
	if (cachedMatch) {
		return cachedMatch;
	}
	
	Match *match = [[Match alloc] init];
	
	match.ID = matchID;
	match.defaultStartingLife = [resultSet intForColumn:@"DefaultStartingLife"];
	match.enablePoisonCounter = [resultSet boolForColumn:@"EnablePoisonCounter"];
	match.enableDynamicCounters = [resultSet boolForColumn:@"EnableDynamicCounters"];
	match.enableTurnTracking = [resultSet boolForColumn:@"EnableTurnTracking"];
	match.startDate = [resultSet dateForColumn:@"StartDate"];
	match.endDate = [resultSet dateForColumn:@"EndDate"];
	
	[self addMatchToCache:match];
	
	return match;
}

+ (MatchTurn *)matchTurnFromResultSet:(FMResultSet *)resultSet {
	NSString *matchTurnID = [[NSString alloc] initWithData:[resultSet dataForColumn:@"ID"] encoding:NSUTF8StringEncoding];
	
	MatchTurn *cachedMatchTurn = [_matchCache objectForKey:matchTurnID];
	if (cachedMatchTurn) {
		return cachedMatchTurn;
	}
	
	MatchTurn *matchTurn = [[MatchTurn alloc] init];
	
	matchTurn.ID = matchTurnID;
	matchTurn.matchID = [[NSString alloc] initWithData:[resultSet dataForColumn:@"MatchID"] encoding:NSUTF8StringEncoding];
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
