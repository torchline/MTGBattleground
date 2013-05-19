//
//  LifeCounterView.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "LifeCounterView.h"
#import "UIView+BasicAnimation.h"
#import "LocalUser.h"
#import "Database.h"

@interface LifeCounterView()

@property (nonatomic) BOOL isSetup;
@property (nonatomic) NSUInteger numSegmentsPerCircle;
@property (nonatomic) UIImage *segmentImage;

// UI
@property (nonatomic) NSMutableArray *segmentImageViews;
@property (nonatomic) UILabel *lifeLabel;
@property (nonatomic) UIButton *upButton;
@property (nonatomic) UIButton *downButton;

@end


@implementation LifeCounterView

#pragma mark - System

- (void)dealloc {
	[self.localUser removeObserver:self forKeyPath:@"life"];
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

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup {
	_enabled = YES;
	
	self.isSetup = NO;
	self.numSegmentsPerCircle = 20;
	self.segmentImage = [UIImage imageNamed:@"LifeCounterSegment.png"];
	self.autoresizingMask = 0;
	self.bounds = CGRectMake(0,
							 0,
							 200,
							 200);
	
	// create life label
	self.lifeLabel = [[UILabel alloc] init];
	self.lifeLabel.backgroundColor = [UIColor clearColor];
	self.lifeLabel.textAlignment = NSTextAlignmentCenter;
	self.lifeLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:50];
	self.lifeLabel.textColor = [UIColor darkTextColor];
	[self addSubview:self.lifeLabel];
	
	// create segments
	self.segmentImageViews = [[NSMutableArray alloc] initWithCapacity:self.numSegmentsPerCircle];
	CGFloat degreeRotationPerSegment = (2 * M_PI) / self.numSegmentsPerCircle;
	
	for (int i = 0; i < self.numSegmentsPerCircle; i++) {
		UIImageView *segmentImageView = [self newSegmentImageView];
		segmentImageView.frame = CGRectMake(0,
											0,
											200,
											200);
		segmentImageView.transform = CGAffineTransformMakeRotation(degreeRotationPerSegment * i);
		
		[self addSubview:segmentImageView];
		[self.segmentImageViews insertObject:segmentImageView atIndex:0];
	}
	
	// create buttons
	UIImage *upButtonImage = [UIImage imageNamed:@"LifeCounterUpButton.png"];
	self.upButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.upButton setImage:upButtonImage forState:UIControlStateNormal];
	self.upButton.frame = CGRectMake(29,
									 23,
									 upButtonImage.size.width,
									 upButtonImage.size.height);
	[self.upButton addTarget:self action:@selector(plusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.upButton];
	
	UIImage *downButtonImage = [UIImage imageNamed:@"LifeCounterDownButton.png"];
	self.downButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.downButton setImage:downButtonImage forState:UIControlStateNormal];
	self.downButton.frame = CGRectMake(29,
									   200 - 23 - downButtonImage.size.height,
									   downButtonImage.size.width,
									   downButtonImage.size.height);
	[self.downButton addTarget:self action:@selector(minusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.downButton];
	
	self.lifeLabel.frame = CGRectMake(25,
									  CGRectGetMaxY(self.upButton.frame),
									  200 - 25 * 2,
									  CGRectGetMinY(self.downButton.frame) - CGRectGetMaxY(self.upButton.frame));
	
	self.isSetup = YES;
	[self updateLifeVisuals];
}


#pragma mark - User Interaction

- (void)plusButtonPressed {
	self.localUser.life++;
}

- (void)minusButtonPressed {
	self.localUser.life--;
}


#pragma mark - Helper

- (UIImageView *)newSegmentImageView {
	UIImageView *segmentImageView = [[UIImageView alloc] initWithImage:self.segmentImage];
	return segmentImageView;
}

- (void)updateLifeVisuals {	
	if (!self.isSetup) {
		return;
	}
		
	self.lifeLabel.text = [[NSString alloc] initWithFormat:@"%d", self.localUser.life];
	
	NSUInteger i = 0;
	for (UIImageView *segmentImageView in self.segmentImageViews) {
		segmentImageView.hidden = i >= self.localUser.life || self.localUser.life <= 0;
		i++;
	}
}

#pragma mark - Protocol

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
	if ([object isEqual:self.localUser] && [keyPath isEqual:@"life"]) {
		[self updateLifeVisuals];
		[Database updateLocalUserActiveState:self.localUser];
	}
}


#pragma mark - Getter / Setter

- (void)setLocalUser:(LocalUser *)localUser {
	[_localUser removeObserver:self forKeyPath:@"life"];
	[localUser addObserver:self forKeyPath:@"life" options:0 context:NULL];
	
	_localUser = localUser;
		
	[self updateLifeVisuals];
}

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
	
	self.userInteractionEnabled = _enabled;
	self.alpha = _enabled ? 1 : 0.60f;
}

@end
