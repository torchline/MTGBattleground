//
//  Match+Runtime.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Match.h"

@class MatchTurn;
@class User;

@interface Match (Runtime)

@property (nonatomic) MatchTurn *currentTurn;
@property (nonatomic) NSArray *users;

@end
