//
//  Match.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Match : NSObject

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *winnerUserID;
@property (nonatomic) NSInteger startingLife;
@property (nonatomic) NSUInteger poisonToDie;
@property (nonatomic) BOOL enablePoisonCounter;
@property (nonatomic) BOOL enableDynamicCounters;
@property (nonatomic) BOOL enableTurnTracking;
@property (nonatomic) BOOL enableAutoDeath;
@property (nonatomic) BOOL enableDamageTargeting;
@property (nonatomic) BOOL isComplete;
@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSDate *endTime;

- (Match *)initWithID:(NSString *)ID
		 winnerUserID:(NSString *)winnerUserID
		 startingLife:(NSInteger)startingLife
		  poisonToDie:(NSUInteger)poisonToDie
		poisonCounter:(BOOL)poisonCounter
	  dynamicCounters:(BOOL)dynamicCounters
		 turnTracking:(BOOL)turnTracking
			autoDeath:(BOOL)autoDeath
	  damageTargeting:(BOOL)damageTargeting
			 complete:(BOOL)complete
			startTime:(NSDate *)startTime
			  endTime:(NSDate *)endTime;

@end
