//
//  MatchStatsManager.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Match;
@class User;

@interface MatchStatsManager : NSObject

+ (double)averageLifeChangePerTurnForUser:(User *)user;
+ (double)averageLifeChangePerTurnForUser:(User *)user match:(Match *)match;

@end
