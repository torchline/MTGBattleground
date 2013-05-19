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

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (UserIconView *)initWithUserIcon:(UserIcon *)userIcon {
	self = [super init];
    if (self) {
		_userIcon = userIcon;
		
        [self setup];
    }
    return self;	
}

- (void)setup {
	self.button = [UIButton buttonWithType:UIButtonTypeCustom];
	self.button.frame = self.bounds;
	[self.button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.button];
	
	// sets up UI
	self.userIcon = self.userIcon;
}


#pragma mark - User Interaction

- (void)buttonPressed {
	if ([self.delegate respondsToSelector:@selector(userIconViewPressed:)]) {
		[self.delegate userIconViewPressed:self];
	}
}


#pragma mark - Getter / Setter

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	
	self.button.frame = self.bounds;
}

- (void)setUserIcon:(UserIcon *)userIcon {
	_userIcon = userIcon;
	
	[self.button setImage:userIcon.image forState:UIControlStateNormal];
}

@end
