//
//  UserState.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/19/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserState.h"

@implementation UserState

- (id <NSCopying>)identifiableID {
	return @(self.localUserID);
}

@end
