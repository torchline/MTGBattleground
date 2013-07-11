//
//  LifeCounterView.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "LifeCounterView.h"
#import "UIView+BasicAnimation.h"
#import "User+Runtime.h"


@implementation LifeCounterView

#pragma mark - System

- (void)dealloc {
	[_user removeObserver:self forKeyPath:@"state.life"];
}



#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _enabled = YES;
		
		_isSetup = NO;
		_numSegmentsPerCircle = 20;
		_segmentImage = [UIImage imageNamed:@"LifeCounterSegment.png"];
		self.autoresizingMask = 0;
		self.bounds = CGRectMake(0,
								 0,
								 200,
								 200);
		
		// create life label
		_lifeLabel = [[UILabel alloc] init];
		_lifeLabel.backgroundColor = [UIColor clearColor];
		_lifeLabel.textAlignment = NSTextAlignmentCenter;
		_lifeLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:50];
		_lifeLabel.textColor = [UIColor darkTextColor];
		[self addSubview:_lifeLabel];
		
		// create segments
		_segmentImageViews = [[NSMutableArray alloc] initWithCapacity:_numSegmentsPerCircle];
		CGFloat degreeRotationPerSegment = (2 * M_PI) / _numSegmentsPerCircle;
		
		for (int i = 0; i < _numSegmentsPerCircle; i++) {
			UIImageView *segmentImageView = [self newSegmentImageView];
			segmentImageView.frame = CGRectMake(0,
												0,
												200,
												200);
			segmentImageView.transform = CGAffineTransformMakeRotation(degreeRotationPerSegment * i);
			
			[self addSubview:segmentImageView];
			[_segmentImageViews insertObject:segmentImageView atIndex:0];
		}
		
		// create buttons
		UIImage *upButtonImage = [UIImage imageNamed:@"LifeCounterUpButton.png"];
		_upButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_upButton setImage:upButtonImage forState:UIControlStateNormal];
		_upButton.frame = CGRectMake(29,
									 23,
									 upButtonImage.size.width,
									 upButtonImage.size.height);
		[_upButton addTarget:self action:@selector(plusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_upButton];
		
		UIImage *downButtonImage = [UIImage imageNamed:@"LifeCounterDownButton.png"];
		_downButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_downButton setImage:downButtonImage forState:UIControlStateNormal];
		_downButton.frame = CGRectMake(29,
									   200 - 23 - downButtonImage.size.height,
									   downButtonImage.size.width,
									   downButtonImage.size.height);
		[_downButton addTarget:self action:@selector(minusButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_downButton];
		
		_lifeLabel.frame = CGRectMake(25,
									  CGRectGetMaxY(_upButton.frame),
									  200 - 25 * 2,
									  CGRectGetMinY(_downButton.frame) - CGRectGetMaxY(_upButton.frame));
		
		_isSetup = YES;
		[self updateLifeVisuals];
    }
    return self;
}


#pragma mark - Public

- (void)commitLifeChange {
	// TODO: recolor life bars to blue
	// TODO: remove red life bars
	_lifeAtLastCommit = _user.state.life;
}


#pragma mark - User Interaction

- (void)plusButtonPressed {
	_user.state.life++;
}

- (void)minusButtonPressed {
	_user.state.life--;
}


#pragma mark - Helper

- (UIImageView *)newSegmentImageView {
	UIImageView *segmentImageView = [[UIImageView alloc] initWithImage:_segmentImage];
	return segmentImageView;
}

- (void)updateLifeVisuals {	
	if (!_isSetup) {
		return;
	}
		
	_lifeLabel.text = [[NSString alloc] initWithFormat:@"%d", _user.state.life];
	
	NSUInteger i = 0;
	for (UIImageView *segmentImageView in _segmentImageViews) {
		segmentImageView.hidden = i >= _user.state.life || _user.state.life <= 0;
		i++;
	}
}

#pragma mark - Protocol

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
		
	if ([object isEqual:_user] && [keyPath isEqual:@"state.life"]) {
		[self updateLifeVisuals];
	}
}


#pragma mark - Getter / Setter

- (void)setUser:(User *)user {
	[_user removeObserver:self forKeyPath:@"state.life"];
	[user addObserver:self forKeyPath:@"state.life" options:0 context:NULL];
	
	_user = user;
	_lifeAtLastCommit = user.state.life;
		
	[self updateLifeVisuals];
}

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
	
	self.userInteractionEnabled = _enabled;
	self.alpha = _enabled ? 1 : 0.60f;
}

@end
