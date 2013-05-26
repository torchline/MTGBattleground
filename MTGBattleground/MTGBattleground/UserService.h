//
//  UserService.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Service.h"

@class User;
@class UserIcon;

@interface UserService : Service

// User
+ (NSMutableArray *)users;
+ (void)updateUser:(User *)user;

// UserIcon
+ (NSMutableArray *)userIcons;
+ (NSMutableDictionary *)userIconDictionary;

@end
