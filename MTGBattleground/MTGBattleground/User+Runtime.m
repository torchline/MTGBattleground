//
//  User+Runtime.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "User+Runtime.h"
#import <objc/runtime.h>

@implementation User (Runtime)

#pragma mark - Getter / Setter

- (void)setIcon:(UserIcon *)icon {
	objc_setAssociatedObject(self, @selector(icon), icon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UserIcon *)icon {
	UserIcon *icon = (UserIcon *)objc_getAssociatedObject(self, @selector(icon));
	
	return icon;
}

- (void)setMeta:(MatchUserMeta *)meta {
	objc_setAssociatedObject(self, @selector(meta), meta, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MatchUserMeta *)meta {
	MatchUserMeta *meta = (MatchUserMeta *)objc_getAssociatedObject(self, @selector(meta));
	
	return meta;
}

- (void)setState:(MatchTurnUserState *)state {
	objc_setAssociatedObject(self, @selector(state), state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MatchTurnUserState *)state {
	MatchTurnUserState *state = (MatchTurnUserState *)objc_getAssociatedObject(self, @selector(state));
	
	return state;
}

@end
