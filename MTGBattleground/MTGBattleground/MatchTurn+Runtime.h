//
//  MatchTurn+Runtime.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchTurn.h"

@class Match;
@class User;

@interface MatchTurn (Runtime)

@property (nonatomic, weak) Match *match;
@property (nonatomic) User *user;

@end
