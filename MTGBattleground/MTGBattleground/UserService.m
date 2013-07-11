//
//  UserService.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserService.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "User+Runtime.h"
#import "UserIcon.h"

#import "Match.h"
#import "MatchTurn.h"
#import "MatchUserMeta.h"


#define FIELDS_USER			@"ID, UserIconID, Name, NumTimesUsed, LastTimeUsed"
#define FIELDS_READ_USER_ICON		@"ID, ImagePath"


@implementation UserService

#pragma mark - Object Builders

+ (User *)userFromResultSet:(FMResultSet *)resultSet {
	User *user;
	NSString *userID = [resultSet stringForColumn:@"ID"];
	
	User *cachedUser = [self userFromCacheWithID:userID];
	if (cachedUser) {
		user = cachedUser;
	}
	else {
		user = [[User alloc] initWithID:userID
								   name:[resultSet stringForColumn:@"Name"]
							 userIconID:[resultSet intForColumn:@"UserIconID"]
						   numTimesUsed:[resultSet intForColumn:@"NumTimesUsed"]
						   lastTimeUsed:[resultSet dateForColumn:@"LastTimeUsed"]];
		
		[self cacheUser:user];
	}
	
	return user;
}

+ (UserIcon *)userIconFromResultSet:(FMResultSet *)resultSet {
	UserIcon *userIcon;
	NSUInteger userIconID = [resultSet intForColumn:@"ID"];
	
	UserIcon *cachedUserIcon = [self userIconFromCacheWithID:userIconID];
	if (cachedUserIcon) {
		userIcon = cachedUserIcon;
	}
	else {
		userIcon = [[UserIcon alloc] initWithID:userIconID
									  imagePath:[resultSet stringForColumn:@"ImagePath"]];
		
		[self cacheUserIcon:userIcon];
	}
	
	return userIcon;
}


#pragma mark - Cache

static NSCache *_userCache = nil;
+ (User *)userFromCacheWithID:(NSString *)userID {
	return [_userCache objectForKey:userID];
}
+ (void)cacheUser:(User *)user {
	if (!_userCache) {
		_userCache = [NSCache new];
	}
	
	[_userCache setObject:user forKey:user.ID];
}

static NSCache *_userIconCache = nil;
+ (UserIcon *)userIconFromCacheWithID:(NSUInteger)userIconID {
	return [_userIconCache objectForKey:@(userIconID)];
}
+ (void)cacheUserIcon:(UserIcon *)userIcon {
	if (!_userIconCache) {
		_userIconCache = [NSCache new];
	}
	
	[_userIconCache setObject:userIcon forKey:@(userIcon.ID)];
}


#pragma mark - User

+ (NSMutableArray *)users {
	NSMutableArray __block *users;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM User", FIELDS_USER];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!users) {
				users = [[NSMutableArray alloc] initWithCapacity:12];
			}
			
			User *user = [self userFromResultSet:resultSet];			
			[users addObject:user];
		}
		
		[resultSet close];
	}];
	
	return users;
}

+ (NSMutableDictionary *)userDictionary {
	NSMutableDictionary __block *userDictionary;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM User", FIELDS_USER];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!userDictionary) {
				userDictionary = [[NSMutableDictionary alloc] initWithCapacity:12];
			}
			
			User *user = [self userFromResultSet:resultSet];
			[userDictionary setObject:user forKey:user.ID];
		}
		
		[resultSet close];
	}];
		
	return userDictionary;
}

+ (NSMutableArray *)usersWithIDs:(NSArray *)userIDs {
	NSMutableArray __block *users;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM User WHERE ID IN (%@)", FIELDS_USER, [userIDs componentsJoinedByString:@", "]];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!users) {
				users = [[NSMutableArray alloc] initWithCapacity:12];
			}
			
			User *user = [self userFromResultSet:resultSet];
			[users addObject:user];
		}
		
		[resultSet close];
	}];
	
	[users sortUsingComparator:^NSComparisonResult(User *user1, User *user2) {
		NSNumber *user1Index = @([userIDs indexOfObject:user1.ID]);
		NSNumber *user2Index = @([userIDs indexOfObject:user2.ID]);
		return [user1Index compare:user2Index];
	}];
	
	return users;
}

+ (NSMutableArray *)usersForMatchUserMetas:(NSArray *)matchUserMetas {
	NSMutableArray *userIDs = [[NSMutableArray alloc] initWithCapacity:[matchUserMetas count]];
	for (MatchUserMeta *matchUserMeta in matchUserMetas) {
		[userIDs addObject:matchUserMeta.userID];
	}
	
	NSMutableArray *users = [self usersWithIDs:userIDs];
	NSAssert([users count] == [matchUserMetas count], @"Users: %@ count does not match Metas: %@ count", users, matchUserMetas);
	
	NSUInteger i = 0;
	for (User *user in users) {
		user.meta = [matchUserMetas objectAtIndex:i];
		i++;
	}
	
	return users;
}



+ (void)updateUser:(User *)user {
	NSAssert(user, @"Cannot update nil User");
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"UPDATE User SET UserIconID = ?, Name = ?, NumTimesUsed = ?, LastTimeUsed = ? WHERE ID = ?";
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						user.userIconID > 0 ? @(user.userIconID) : [NSNull null],
						user.name,
						@(user.numTimesUsed),
						@((unsigned long)[user.lastTimeUsed timeIntervalSince1970]),
						user.ID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
		
		if (success) {
			[self cacheUser:user];
		}
	}];
}



+ (void)createUser:(User *)user {
	NSAssert(user, @"Cannot create nil User"); // ID, UserIconID, Name, NumTimesUsed, LastTimeUsed
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO User (%@) VALUES (?, ?, ?, ?, ?)", FIELDS_USER];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						user.ID,
						user.userIconID > 0 ? @(user.userIconID) : [NSNull null],
						user.name,
						@(user.numTimesUsed),
						@((unsigned long)[user.lastTimeUsed timeIntervalSince1970])
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
		
		if (success) {
			[self cacheUser:user];
		}
	}];
}



+ (BOOL)doesUsernameExist:(NSString *)username {
	BOOL __block exists = NO;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"SELECT COUNT(1) AS Count FROM User WHERE Name = ?";
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  username
								  ]];
		
		if ([resultSet next]) {
			NSUInteger count = [resultSet intForColumn:@"Count"];
			exists = count > 0;
		}
		
		[resultSet close];
	}];
	
	return exists;
}


#pragma mark UserIcon

+ (NSMutableArray *)userIcons {
	NSMutableArray __block *userIcons;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM UserIcon", FIELDS_READ_USER_ICON];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!userIcons) {
				userIcons = [[NSMutableArray alloc] initWithCapacity:20];
			}
			
			UserIcon *userIcon = [self userIconFromResultSet:resultSet];
			
			[userIcons addObject:userIcon];
		}
		
		[resultSet close];
	}];
	
	return userIcons;
}

+ (NSMutableDictionary *)userIconMapWithIDs:(NSArray *)userIconIDs {
	NSMutableDictionary __block *userIcons;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM UserIcon WHERE ID IN (%@)", FIELDS_READ_USER_ICON, [userIconIDs componentsJoinedByString:@", "]];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!userIcons) {
				userIcons = [[NSMutableDictionary alloc] initWithCapacity:20];
			}
			
			UserIcon *userIcon = [self userIconFromResultSet:resultSet];
			
			[userIcons setObject:userIcon forKey:@(userIcon.ID)];
		}
		
		[resultSet close];
	}];
	
	return userIcons;
}

+ (NSMutableArray *)userIconsForUsers:(NSArray *)users {
	NSMutableArray *userIconIDs = [[NSMutableArray alloc] initWithCapacity:[users count]];
	for (User *user in users) {
		[userIconIDs addObject:@(user.userIconID)];
	}
	
	NSMutableDictionary *userIconMap = [self userIconMapWithIDs:userIconIDs];
	
	NSMutableArray *userIcons = [[NSMutableArray alloc] initWithCapacity:[users count]];
	for (User *user in users) {
		UserIcon *userIcon = [userIconMap objectForKey:@(user.userIconID)];
		NSAssert(userIcon, @"UserIcon %d not found for User %@", user.userIconID, user.name);
		[userIcons addObject:userIcon];
	}
	
	return userIcons;
}

+ (NSMutableDictionary *)userIconDictionary {
	NSMutableDictionary __block *userIconDictionary;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM UserIcon", FIELDS_READ_USER_ICON];
		FMResultSet *resultSet = [db executeQuery:query];
		
		while ([resultSet next]) {
			if (!userIconDictionary) {
				userIconDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
			}
			
			UserIcon *userIcon = [self userIconFromResultSet:resultSet];
			
			[userIconDictionary setObject:userIcon forKey:@(userIcon.ID)];
		}
		
		[resultSet close];
	}];
	
	return userIconDictionary;
}





@end
