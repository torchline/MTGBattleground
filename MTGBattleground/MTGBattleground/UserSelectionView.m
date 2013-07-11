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


@implementation UserSelectionView

#pragma mark - System

- (void)dealloc {
	[_user removeObserver:self forKeyPath:@"icon"];
}


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (id)initWithUser:(User *)user {
	self = [self init];
	if (self) {
		self.user = user;
	}
	return self;
}

- (void)setup {
	// Username Button
	_nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_nameButton.titleLabel.textAlignment = NSTextAlignmentLeft;
	_nameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	_nameButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
	[_nameButton addTarget:self action:@selector(nameButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_nameButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:40];
	_nameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
	[_nameButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
	[_nameButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
	[_nameButton setTitle:@"None" forState:UIControlStateNormal];
	if ([_nameButton respondsToSelector:@selector(setMinimumScaleFactor:)]) {
		_nameButton.titleLabel.minimumScaleFactor = 0.7f;
	}
	else if ([_nameButton respondsToSelector:@selector(setMinimumFontSize:)]) {
		_nameButton.titleLabel.minimumFontSize = 0.7f * 28;
	}
	[self addSubview:_nameButton];
	
	// User Icon
	_iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
	//_iconButton.backgroundColor = [UIColor yellowColor];
	[_iconButton addTarget:self action:@selector(iconButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_iconButton.hidden = YES; // not visible until user is set
	[self addSubview:_iconButton];
	
	// Unset Button
	_unsetButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_unsetButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:50];
	[_unsetButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
	[_unsetButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
	[_unsetButton setTitle:@"x" forState:UIControlStateNormal];
	[_unsetButton addTarget:self action:@selector(unsetButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_unsetButton.hidden = YES; // not visible until user is set
	[self addSubview:_unsetButton];
}


#pragma mark - System

- (void)layoutSubviews {
	if (_isOpen) {
		_nameButton.frame = CGRectMake(150,
									   0,
									   150,
									   150);
	}
	else {
		_nameButton.frame = CGRectMake(50,
									   0,
									   200,
									   150);
	}
	
	_iconButton.frame = CGRectMake(0,
								   0,
								   150,
								   150);
	
	_unsetButton.frame = CGRectMake(150 + 200,
									0,
									70,
									140);
}


#pragma mark - User Interaction

- (void)nameButtonPressed {
	[_delegate userSelectionViewDidRequestNewName:self];
}

- (void)iconButtonPressed {
	[_delegate userSelectionViewDidRequestNewIcon:self];
}

- (void)unsetButtonPressed {
	self.user = nil;
}


#pragma mark - Animation

- (void)animateOpen {
	if (_isOpen) {
		return;
	}
	
	_isOpen = YES;
	
	//[_iconButton showByExpandingForDuration:0.30f completion:nil];
	_iconButton.transform = CGAffineTransformMakeScale(0.001, 0.001);
	_iconButton.hidden = NO;
	
	_unsetButton.alpha =  0;
	_unsetButton.hidden = NO;

	[UIView animateWithDuration:0.20f
					 animations:^{
						 _nameButton.frame = CGRectMake(150,
														0,
														150,
														150);
						 
						 _iconButton.transform = CGAffineTransformIdentity;
						 
						 _unsetButton.alpha = 1;
					 }];
}

- (void)animateClosed {
	if (!_isOpen) {
		return;
	}
	
	_isOpen = NO;	
	
	_unsetButton.hidden = YES;
	
	[UIView animateWithDuration:0.20f
					 animations:^{
						 _nameButton.frame = CGRectMake(50,
														0,
														150,
														150);
						 
						 _iconButton.transform = CGAffineTransformMakeScale(0.001, 0.001);						 
					 }
					 completion:^(BOOL finished) {
						 _iconButton.hidden = YES;
						 _iconButton.transform = CGAffineTransformIdentity;
					 }];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {	
	if ([object isKindOfClass:[User class]] && [keyPath isEqualToString:@"icon"]) {
		[_iconButton setImage:_user.icon.image forState:UIControlStateNormal];
	}
}


#pragma mark - Getter / Setter

- (void)setUser:(User *)user {
	[_user removeObserver:self forKeyPath:@"icon"];
	[user addObserver:self forKeyPath:@"icon" options:0 context:NULL];
		
	if (user) {
		[_nameButton setTitle:user.name forState:UIControlStateNormal];
		
		[_iconButton setImage:user.icon.image forState:UIControlStateNormal];
		
		[self animateOpen];
	}
	else {
		[_nameButton setTitle:@"None" forState:UIControlStateNormal];
		[self animateClosed];
	}
		
	_user = user;
}

@end
