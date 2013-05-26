//
//  UserSelectionView.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserSelectionView.h"
#import "UserIcon.h"
#import "User+Runtime.h"
#import "UIView+BasicAnimation.h"

@interface UserSelectionView ()

@property (nonatomic) BOOL isOpen;

@end


@implementation UserSelectionView

#pragma mark - System

- (void)dealloc {
	[self.user removeObserver:self forKeyPath:@"icon"];
}


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

- (UserSelectionView *)initWithUser:(User *)user {
	self = [super init];
	if (self) {
		_user = user;
		[self setup];
	}
	return self;
}

- (void)setup {
	// create name button
	self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//self.nameButton.backgroundColor = [UIColor blueColor];
	self.nameButton.titleLabel.textAlignment = NSTextAlignmentLeft;
	self.nameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	self.nameButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
	[self.nameButton addTarget:self action:@selector(nameButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.nameButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:40];
	self.nameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
	[self.nameButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[self.nameButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
	self.nameButton.frame = CGRectMake(50, 0, 200, 150);
	if ([self.nameButton respondsToSelector:@selector(setMinimumScaleFactor:)]) {
		self.nameButton.titleLabel.minimumScaleFactor = 0.7f;
	}
	else if ([self.nameButton respondsToSelector:@selector(setMinimumFontSize:)]) {
		self.nameButton.titleLabel.minimumFontSize = 0.7f * 28;
	}
	[self addSubview:self.nameButton];
	
	// create icon button
	self.iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//self.iconButton.backgroundColor = [UIColor yellowColor];
	[self.iconButton addTarget:self action:@selector(iconButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.iconButton.frame = CGRectMake(0, 0, 150, 150);
	self.iconButton.hidden = YES; // not visible until user is set
	[self addSubview:self.iconButton];

	// create unset button
	self.unsetButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.unsetButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:50];
	[self.unsetButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
	[self.unsetButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
	[self.unsetButton setTitle:@"x" forState:UIControlStateNormal];
	[self.unsetButton addTarget:self action:@selector(unsetButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.unsetButton.frame = CGRectMake(150 + 200, 0, 70, 140);
	self.unsetButton.hidden = YES; // not visible until user is set
	[self addSubview:self.unsetButton];
	
	// sets up UI
	self.user = self.user;
}


#pragma mark - User Interaction

- (void)nameButtonPressed {
	if ([self.delegate respondsToSelector:@selector(userSelectionViewDidRequestNewName:)]) {
		[self.delegate userSelectionViewDidRequestNewName:self];
	}
}

- (void)iconButtonPressed {
	if ([self.delegate respondsToSelector:@selector(userSelectionViewDidRequestNewIcon:)]) {
		[self.delegate userSelectionViewDidRequestNewIcon:self];
	}
}

- (void)unsetButtonPressed {
	self.user = nil;
}


#pragma mark - Animation

- (void)animateOpen {
	if (self.isOpen) {
		return;
	}
	
	self.isOpen = YES;
	
	//[self.iconButton showByExpandingForDuration:0.30f completion:nil];
	self.iconButton.transform = CGAffineTransformMakeScale(0.001, 0.001);
	self.iconButton.hidden = NO;
	
	self.unsetButton.alpha =  0;
	self.unsetButton.hidden = NO;

	[UIView animateWithDuration:0.20f
					 animations:^{
						 self.nameButton.frame = CGRectMake(150,
															0,
															150,
															150);
						 
						 self.iconButton.transform = CGAffineTransformIdentity;
						 
						 self.unsetButton.alpha = 1;
					 }];
}

- (void)animateClosed {
	if (!self.isOpen) {
		return;
	}
	
	self.isOpen = NO;
	
	self.unsetButton.hidden = YES;
	
	[UIView animateWithDuration:0.20f
					 animations:^{
						 self.nameButton.frame = CGRectMake(50,
															0,
															150,
															150);
						 
						 self.iconButton.transform = CGAffineTransformMakeScale(0.001, 0.001);						 
					 }
					 completion:^(BOOL finished) {
						 self.iconButton.hidden = YES;
						 self.iconButton.transform = CGAffineTransformIdentity;
					 }];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {	
	if ([object isKindOfClass:[User class]] && [keyPath isEqualToString:@"icon"]) {
		[self.iconButton setImage:self.user.icon.image forState:UIControlStateNormal];
	}
}



#pragma mark - Getter / Setter

- (void)setUser:(User *)user {
	[_user removeObserver:self forKeyPath:@"icon"];
	[user addObserver:self forKeyPath:@"icon" options:0 context:NULL];
	
	_user = nil;
	
	if (user) {
		[self.nameButton setTitle:user.name forState:UIControlStateNormal];
		
		[self.iconButton setImage:user.icon.image forState:UIControlStateNormal];
		
		[self animateOpen];
	}
	else {
		[self.nameButton setTitle:@"None" forState:UIControlStateNormal];
		[self animateClosed];
	}
		
	_user = user; // deferred so user record doesn't get updated user icon
}

- (void)setUserIcon:(UserIcon *)userIcon {
	
}

@end
