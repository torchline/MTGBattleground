//
//  Settings.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Settings.h"
#import "Database.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "FMResultSet.h"

@implementation Settings

#pragma mark - Public

+ (NSString *)stringForKey:(NSString *)key {
	id __block value;
	
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT Value FROM Settings WHERE Key = '%@'", key];
		FMResultSet *resultSet = [db executeQuery:query];
		NSAssert([resultSet next], @"No setting value found with key: %@", key);
		value = [resultSet stringForColumnIndex:0];
		[resultSet close];
	}];
	
	return value;
}

+ (void)setString:(NSString *)string forKey:(NSString *)key {
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Settings SET Value = ? WHERE Key = '%@'", key];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						string
						]];

		NSAssert(success, @"Failed updating setting string (%@) with key: %@", string, key);
	}];
}

+ (NSString *)dataAsStringForKey:(NSString *)key {
	NSData * __block value;
	
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT Value FROM Settings WHERE Key = '%@'", key];
		FMResultSet *resultSet = [db executeQuery:query];
		NSAssert([resultSet next], @"No setting value found with key: %@", key);
		value = [resultSet dataForColumnIndex:0];
		[resultSet close];
	}];
	
	NSString *string;
	if (value) {
		string = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
	}
	
	return string;
}

+ (void)setStringAsData:(NSString *)string forKey:(NSString *)key {
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Settings SET Value = ? WHERE Key = '%@'", key];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						[string dataUsingEncoding:NSUTF8StringEncoding]
						]];
		
		NSAssert(success, @"Failed updating setting string as data (%@) with key: %@", string, key);
	}];
}

+ (void)setNullValueForKey:(NSString *)key {
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Settings SET Value = NULL WHERE Key = '%@'", key];
		BOOL success = [db executeUpdate:query];
		
		NSAssert(success, @"Failed updating setting NULL value with key: %@", key);
	}];
}


@end
