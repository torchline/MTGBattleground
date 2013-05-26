//
//  Settings.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Settings.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "Service.h"

@implementation Settings

#pragma mark - Public

+ (NSString *)stringForKey:(NSString *)key {
	id __block value;
	
	[[Service fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"SELECT Value FROM Settings WHERE Key = '%@'", key];
		FMResultSet *resultSet = [db executeQuery:query];
		NSAssert([resultSet next], @"No setting value found with key: %@", key);
		value = [resultSet stringForColumnIndex:0];
		[resultSet close];
	}];
	
	return value;
}

+ (void)setString:(NSString *)string forKey:(NSString *)key {
	[[Service fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = [[NSString alloc] initWithFormat:@"UPDATE Settings SET Value = ? WHERE Key = '%@'", key];
		BOOL success = [db executeUpdate:query withArgumentsInArray:@[
						string ? string : [NSNull null]
						]];

		NSAssert(success, @"Failed updating setting string (%@) with key: %@", string, key);
	}];
}

@end
