//
//  MatchTurn.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MatchTurn : NSObject

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *matchID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSUInteger turnNumber;
@property (nonatomic) NSDate *passTime;

- (MatchTurn *)initWithID:(NSString *)ID
				  matchID:(NSString *)matchID
				   userID:(NSString *)userID
			   turnNumber:(NSUInteger)turnNumber
				 passTime:(NSDate *)passTime;

@end
