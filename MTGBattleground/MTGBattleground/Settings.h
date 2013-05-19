//
//  Settings.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SETTINGS_CURRENT_ACTIVE_MATCH_ID		@"CurrentActiveMatchID"
#define SETTINGS_MATCH_STARTING_LIFE			@"MatchStartingLife"
#define SETTINGS_MATCH_ENABLE_POISON_COUNTER	@"MatchEnablePoisonCounter"
#define SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS	@"MatchEnableDynamicCounters"
#define SETTINGS_MATCH_ENABLE_TURN_TRACKING		@"MatchEnableTurnTracking"


@interface Settings : NSObject

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)dataAsStringForKey:(NSString *)key;

+ (void)setString:(NSString *)string forKey:(NSString *)key;
+ (void)setStringAsData:(NSString *)string forKey:(NSString *)key;

+ (void)setNullValueForKey:(NSString *)key;

@end
