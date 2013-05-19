//
//  LocalUser.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentifiableDatabaseObject.h"

typedef enum : NSUInteger {
	UserSlotSouth = 1,
	UserSlotWest,
	UserSlotNorth,
	UserSlotEast
} UserSlot;

@class UserIcon;

@interface LocalUser : NSObject <IdentifiableDatabaseObject>

// standard
@property (nonatomic) NSUInteger ID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSUInteger userIconID;
@property (nonatomic) NSUInteger numTimesUsed;
@property (nonatomic) NSDate *lastDateUsed;

// active only
@property (nonatomic) NSInteger life;
@property (nonatomic) NSInteger poison;
@property (nonatomic) UserSlot userSlot;

// runtime
@property (nonatomic) UserIcon *userIcon;

@end
