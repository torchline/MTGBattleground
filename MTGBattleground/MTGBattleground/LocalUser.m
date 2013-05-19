//
//  LocalUser.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "LocalUser.h"
#import "UserIcon.h"

@implementation LocalUser

#pragma mark - Getter / Setter

- (void)setUserIconID:(NSUInteger)userIconID {
	_userIconID = userIconID;
	
	if (_userIcon.ID != userIconID) {
		_userIcon = nil;
	}
}
- (void)setUserIcon:(UserIcon *)userIcon {
	_userIcon = userIcon;
	_userIconID = userIcon.ID;
}


#pragma mark - Interface
#pragma mark Identifiable

- (id)identifiableID {
	return @(self.ID);
}

@end
