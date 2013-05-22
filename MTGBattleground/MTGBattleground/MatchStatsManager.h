//
//  MatchStatsManager.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Match;
@class LocalUser;

@interface MatchStatsManager : NSObject

+ (double)averageLifeChangePerTurnForLocalUser:(LocalUser *)localUser;
+ (double)averageLifeChangePerTurnForLocalUser:(LocalUser *)localUser match:(Match *)match;

@end
