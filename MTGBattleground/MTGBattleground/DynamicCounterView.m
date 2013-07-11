//
//  DynamicCounterView.m
//  MTGBattleground
//
//  Created by Brad Walker on 6/30/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "DynamicCounterView.h"
#import <QuartzCore/CALayer.h>

@implementation DynamicCounterView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor darkGrayColor];
		
		_label = [UILabel new];
		_label.backgroundColor = [UIColor clearColor];
		_label.textColor = [UIColor whiteColor];
		_label.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:32];
		_label.textAlignment = UITextAlignmentCenter;
		[self addSubview:_label];
		
		_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized)];
		_panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized)];
		_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized)];
		
		[_tapGestureRecognizer requireGestureRecognizerToFail:_panGestureRecognizer];
		
		[self addGestureRecognizer:_panGestureRecognizer];
		[self addGestureRecognizer:_tapGestureRecognizer];
		[self addGestureRecognizer:_longPressGestureRecognizer];
		
		self.count = 1;
	}
	return self;
}


#pragma mark - System

- (void)layoutSubviews {
	self.layer.cornerRadius = self.bounds.size.width / 2;
	_label.frame = self.bounds;
}


#pragma mark - User Interaction

- (void)tapGestureRecognized {
	switch (_tapGestureRecognizer.state) {
		case UIGestureRecognizerStateEnded:
			self.count++;
			break;
			
		default:
			break;
	}
}

- (void)panGestureRecognized {	
	switch (_panGestureRecognizer.state) {
		case UIGestureRecognizerStateBegan: {
			CGPoint velocity = [_panGestureRecognizer velocityInView:self];
			
			if (velocity.y < 0) {
				self.count++;
				_panGestureRecognizer.enabled = NO;
			}
			else if (velocity.y > 0) {
				self.count--;
				_panGestureRecognizer.enabled = NO;
			}
		}	break;
			
		case UIGestureRecognizerStateCancelled:
			_panGestureRecognizer.enabled = YES;
			break;
			
		default:
			break;
	}
}

- (void)longPressGestureRecognized {
	switch (_longPressGestureRecognizer.state) {
		case UIGestureRecognizerStateBegan: {
			[_delegate dynamicCounterViewDidRequestToBeDeleted:self];
		}	break;
			
		default:
			break;
	}
}


#pragma mark - Getter / Setter

- (void)setCount:(NSInteger)count {
	_count = count;
	_label.text = [[NSString alloc] initWithFormat:@"%d", count];
}

@end
