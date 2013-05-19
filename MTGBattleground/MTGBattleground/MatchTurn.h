//
//  MatchTurn.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/12/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentifiableDatabaseObject.h"

@interface MatchTurn : NSObject

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *matchID;
@property (nonatomic) NSUInteger localUserID;
@property (nonatomic) NSDate *endDate;

@end
