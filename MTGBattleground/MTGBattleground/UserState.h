//
//  UserState.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/19/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MatchAccess.h"
#import "IdentifiableDatabaseObject.h"

@interface UserState : NSObject <IdentifiableDatabaseObject>

@property (nonatomic) NSUInteger localUserID;
@property (nonatomic) UserSlot userSlot;
@property (nonatomic) NSInteger life;
@property (nonatomic) NSUInteger poison;

@end
