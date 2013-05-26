//
//  MatchTurn+Runtime.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchTurn+Runtime.h"
#import <objc/runtime.h>
#import "User+Runtime.h"
#import "Match+Runtime.h"

@implementation MatchTurn (Runtime)

- (void)setMatch:(Match *)match {
	objc_setAssociatedObject(self, @selector(match), match, OBJC_ASSOCIATION_ASSIGN);
}

- (Match *)match {
	return (Match *)objc_getAssociatedObject(self, @selector(match));
}

- (void)setUser:(User *)user {
	objc_setAssociatedObject(self, @selector(user), user, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (User *)user {
	return (User *)objc_getAssociatedObject(self, @selector(user));	
}

@end
