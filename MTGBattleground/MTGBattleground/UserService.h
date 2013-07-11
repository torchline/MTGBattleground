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
+ (NSMutableDictionary *)userDictionary;
+ (NSMutableArray *)usersWithIDs:(NSArray *)userIDs;
+ (NSMutableArray *)usersForMatchUserMetas:(NSArray *)matchUserMetas;
+ (void)updateUser:(User *)user;
+ (void)createUser:(User *)user;
+ (BOOL)doesUsernameExist:(NSString *)username;

// UserIcon
+ (NSMutableArray *)userIcons;
+ (NSMutableDictionary *)userIconMapWithIDs:(NSArray *)userIconIDs;
+ (NSMutableArray *)userIconsForUsers:(NSArray *)users;
+ (NSMutableDictionary *)userIconDictionary;

@end
