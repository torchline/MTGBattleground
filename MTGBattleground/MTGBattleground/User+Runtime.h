//
//  User+Runtime.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "User.h"
#import "UserIcon.h"
#import "MatchUserMeta.h"
#import "MatchTurnUserState.h"

@class UserIcon;
@class MatchUserMeta;
@class MatchTurnUserState;

@interface User (Runtime)

@property (nonatomic) UserIcon *icon;
@property (nonatomic) MatchUserMeta *meta;
@property (nonatomic) MatchTurnUserState *state;

@end
