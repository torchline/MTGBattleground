//
//  MatchStatsManager.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchStatsManager.h"
#import "Database.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "Match.h"
#import "LocalUser.h"

@implementation MatchStatsManager

+ (double)averageLifeChangePerTurnForLocalUser:(LocalUser *)localUser {
	double __block averageLifeChangePerTurn;
	
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"SELECT ((SELECT SUM(Life) FROM Match_LocalUser_finalUserState WHERE LocalUserID = ?) - (SELECT SUM(Life) FROM Match_LocalUser_initialUserState WHERE LocalUserID = ?)) / CAST((SELECT COUNT(mt.ID) FROM MatchTurn mt INNER JOIN MatchTurn_LocalUser_userState mt_lu_us ON mt.ID = mt_lu_us.MatchTurnID WHERE mt_lu_us.LocalUserID = ? AND mt_lu_us.IsDead = 0) AS REAL) AS AverageLifeChangePerTurn";
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  @(localUser.ID),
								  @(localUser.ID),
								  @(localUser.ID)
								  ]];
		
		NSAssert([resultSet next], @"Failed fetching average life change per turn for LocalUser %d", localUser.ID);
		
		averageLifeChangePerTurn = [resultSet doubleForColumn:@"AverageLifeChangePerTurn"];
		
		[resultSet close];
	}];
	
	return averageLifeChangePerTurn;
}

+ (double)averageLifeChangePerTurnForLocalUser:(LocalUser *)localUser match:(Match *)match {
	double __block averageLifeChangePerTurn;
	
	NSNumber *userID = @(localUser.ID);
	
	[[Database fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT (f.Life - i.Life) / CAST (COUNT(mt.ID) AS REAL) AS AverageLifeChangePerTurn FROM MATCH m INNER JOIN MatchTurn mt ON m.ID = mt.MatchID INNER JOIN Match_LocalUser_finalUserState f ON m.ID = f.MatchID INNER JOIN Match_LocalUser_initialUserState i ON m.ID = i.MatchID WHERE m.ID = ? AND f.LocalUserID = ? AND i.LocalUserID = ?"
							 withArgumentsInArray:@[
								  match.ID,
								  userID,
								  userID
								  ]];
		
		NSAssert([resultSet next], @"Failed fetching average life change per turn for LocalUser %d and Match %@", localUser.ID, match.ID);
		
		averageLifeChangePerTurn = [resultSet doubleForColumn:@"AverageLifeChangePerTurn"];
		
		[resultSet close];
	}];
	
	return averageLifeChangePerTurn;
}

@end
