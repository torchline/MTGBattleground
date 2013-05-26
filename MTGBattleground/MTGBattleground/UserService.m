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

#import "User.h"
#import "UserIcon.h"

#import "Match.h"
#import "MatchTurn.h"


#define FIELDS_READ_USER			@"ID, UserIconID, Name, NumTimesUsed, LastTimeUsed"
#define FIELDS_UPDATE_USER			@"UserIconID = ?, Name = ?, NumTimesUsed = ?, LastTimeUsed = ?"

#define FIELDS_READ_USER_ICON		@"ID, ImagePath"
#define FIELDS_UPDATE_USER_ICON		@"ImagePath = ?"


@implementation UserService

#pragma mark - Object Builders

+ (User *)userFromResultSet:(FMResultSet *)resultSet {
	return [[User alloc] initWithID:[resultSet stringForColumn:@"ID"]
							   name:[resultSet stringForColumn:@"Name"]
						 userIconID:[resultSet intForColumn:@"UserIconID"]
					   numTimesUsed:[resultSet intForColumn:@"NumTimesUsed"]
					   lastTimeUsed:[resultSet dateForColumn:@"LastTimeUsed"]];
}

+ (UserIcon *)userIconFromResultSet:(FMResultSet *)resultSet {
	return [[UserIcon alloc] initWithID:[resultSet intForColumn:@"ID"]
							  imagePath:[resultSet stringForColumn:@"ImagePath"]];
}


#pragma mark - User

+ (NSMutableArray *)users {
	NSMutableArray __block *users;
	
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT %@ FROM User", FIELDS_READ_USER];
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

+ (void)updateUser:(User *)user {
	[[self fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE User SET %@ WHERE ID = ?", FIELDS_UPDATE_USER];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						user.userIconID > 0 ? @(user.userIconID) : [NSNull null],
						user.name,
						@(user.numTimesUsed),
						@((unsigned long)[user.lastTimeUsed timeIntervalSince1970]),
						user.ID
						]];
		
		NSAssert(success, @"%@", [db lastErrorMessage]);
	}];
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
