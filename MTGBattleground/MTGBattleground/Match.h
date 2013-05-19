//
//  Match.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentifiableDatabaseObject.h"

@interface Match : NSObject <IdentifiableDatabaseObject>

@property (nonatomic) NSString *ID;
@property (nonatomic) NSInteger defaultStartingLife;
@property (nonatomic) BOOL enablePoisonCounter;
@property (nonatomic) BOOL enableDynamicCounters;
@property (nonatomic) BOOL enableTurnTracking;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;

@end
