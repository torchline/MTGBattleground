//
//  LocalUser.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentifiableDatabaseObject.h"
#import "UserState.h"
#import "UserIcon.h"
#import "MatchAccess.h"

@class UserIcon;
@class UserState;

@interface LocalUser : NSObject <IdentifiableDatabaseObject>

// standard
@property (nonatomic) NSUInteger ID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSUInteger userIconID;
@property (nonatomic) NSUInteger numTimesUsed;
@property (nonatomic) NSDate *lastDateUsed;

@property (nonatomic) UserState *state;

// runtime
@property (nonatomic) UserIcon *userIcon;

@end
