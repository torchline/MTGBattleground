//
//  MatchStatsManager.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchStatsManager.h"

#import "MatchService.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "Match.h"
#import "User.h"

@implementation MatchStatsManager

+ (double)averageLifeChangePerTurnForUser:(User *)user {
	double __block averageLifeChangePerTurn;
	
	[[Service fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		NSString *query = @"SELECT ((SELECT SUM(Life) FROM Match_User_finalUserState WHERE UserID = ?) - (SELECT SUM(Life) FROM Match_User_initialUserState WHERE UserID = ?)) / CAST((SELECT COUNT(mt.ID) FROM MatchTurn mt INNER JOIN MatchTurn_User_userState mt_lu_us ON mt.ID = mt_lu_us.MatchTurnID WHERE mt_lu_us.UserID = ? AND mt_lu_us.IsDead = 0) AS REAL) AS AverageLifeChangePerTurn";
		FMResultSet *resultSet = [db executeQuery:query withArgumentsInArray:@[
								  user.ID,
								  user.ID,
								  user.ID
								  ]];
		
		NSAssert([resultSet next], @"Failed fetching average life change per turn for User %@", user.ID);
		
		averageLifeChangePerTurn = [resultSet doubleForColumn:@"AverageLifeChangePerTurn"];
		
		[resultSet close];
	}];
	
	return averageLifeChangePerTurn;
}

+ (double)averageLifeChangePerTurnForUser:(User *)user match:(Match *)match {
	double __block averageLifeChangePerTurn;
		
	[[Service fmDatabaseQueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:@"SELECT (f.Life - i.Life) / CAST (COUNT(mt.ID) AS REAL) AS AverageLifeChangePerTurn FROM MATCH m INNER JOIN MatchTurn mt ON m.ID = mt.MatchID INNER JOIN Match_User_finalUserState f ON m.ID = f.MatchID INNER JOIN Match_User_initialUserState i ON m.ID = i.MatchID WHERE m.ID = ? AND f.UserID = ? AND i.UserID = ?"
							 withArgumentsInArray:@[
								  match.ID,
								  user.ID,
								  user.ID
								  ]];
		
		NSAssert([resultSet next], @"Failed fetching average life change per turn for User %@ and Match %@", user.ID, match.ID);
		
		averageLifeChangePerTurn = [resultSet doubleForColumn:@"AverageLifeChangePerTurn"];
		
		[resultSet close];
	}];
	
	return averageLifeChangePerTurn;
}

@end
