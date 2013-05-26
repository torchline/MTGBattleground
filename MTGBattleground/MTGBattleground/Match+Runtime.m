//
//  Match+Runtime.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Match+Runtime.h"
#import <objc/runtime.h>
#import "MatchTurn+Runtime.h"
#import "User+Runtime.h"

@implementation Match (Runtime)

- (void)setCurrentTurn:(MatchTurn *)currentTurn {
	objc_setAssociatedObject(self, @selector(currentTurn), currentTurn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MatchTurn *)currentTurn {
	MatchTurn *currentTurn = (MatchTurn *)objc_getAssociatedObject(self, @selector(currentTurn));
	
	return currentTurn;
}

- (void)setUsers:(NSArray *)users {
	objc_setAssociatedObject(self, @selector(users), users, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)users {
	NSArray *users = (NSArray *)objc_getAssociatedObject(self, @selector(users));
	
	return users;
}

@end
