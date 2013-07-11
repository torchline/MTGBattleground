//
//  UserIconView.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserIconView.h"
#import "UserIcon.h"

@implementation UserIconView

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
		[_button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_button];
    }
    return self;
}

- (UserIconView *)initWithUserIcon:(UserIcon *)userIcon {
	self = [self init];
    if (self) {
		self.userIcon = userIcon;
    }
    return self;	
}


#pragma mark - System

- (void)layoutSubviews {
	_button.frame = self.bounds;
}


#pragma mark - User Interaction

- (void)buttonPressed {
	[_delegate userIconViewPressed:self];
}


#pragma mark - Getter / Setter

- (void)setUserIcon:(UserIcon *)userIcon {
	_userIcon = userIcon;
	
	[_button setImage:userIcon.image forState:UIControlStateNormal];
}

@end
