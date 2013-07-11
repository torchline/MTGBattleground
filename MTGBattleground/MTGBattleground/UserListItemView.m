//
//  UserListItemView.m
//  MTGBattleground
//
//  Created by Brad Walker on 7/3/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserListItemView.h"
#import "User+Runtime.h"
#import <QuartzCore/CALayer.h>
#import "UIColor+Pastel.h"

@implementation UserListItemView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_padding = UIEdgeInsetsMake(15, 15, 15, 15);
		
        _label = [UILabel new];
		_label.backgroundColor = [UIColor clearColor];
		_label.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:24];
		[self addSubview:_label];
		
		_selectedBackgroundLayer = [CALayer new];
		_selectedBackgroundLayer.backgroundColor = [UIColor tealPastelColor].CGColor;
    }
    return self;
}


#pragma mark - System

- (void)layoutSubviews {
	CGFloat contentHeight = self.bounds.size.height - _padding.top - _padding.bottom;
	CGFloat contentWidth = self.bounds.size.width - _padding.left - _padding.right;
	
	_label.frame = CGRectMake(_padding.left,
							  _padding.top,
							  contentWidth,
							  contentHeight);
	
	_selectedBackgroundLayer.frame = self.bounds;
}


#pragma mark - Public

+ (CGFloat)minimumHeight {
	return 50;
}

+ (Class)objectClass {
	return [User class];
}


#pragma mark - Getter / Setter

- (void)setObject:(id)object {
	[super setObject:object];
	
	User *user = (User *)object;
	_label.text = user.name;
}

- (void)setState:(ObjectListItemViewState)state animated:(BOOL)animated {
	[super setState:state animated:animated];
	
	switch (state) {
		case ObjectListItemViewStateNormal: {
			if (animated) {
				[UIView animateWithDuration:animated ? 0.20f : 0
								 animations:^{
									 _selectedBackgroundLayer.opacity = 0;
								 }
								 completion:^(BOOL finished) {
									 [_selectedBackgroundLayer removeFromSuperlayer];
								 }];
			}
			else {
				_selectedBackgroundLayer.opacity = 0;
				[_selectedBackgroundLayer removeFromSuperlayer];
			}
			
			_label.textColor = [UIColor darkGrayColor];
		}	break;
		case ObjectListItemViewStateSelected: {
			_selectedBackgroundLayer.opacity = 0;
			[self.layer insertSublayer:_selectedBackgroundLayer atIndex:0];
			
			if (animated) {
				[UIView animateWithDuration:animated ? 0.20f : 0
								 animations:^{
									 _selectedBackgroundLayer.opacity = 1;
								 }];
			}
			else {
				_selectedBackgroundLayer.opacity = 1;
			}
			
			_label.textColor = [UIColor darkTextColor];
		}	break;
		case ObjectListItemViewStateEditing: {
			if (animated) {
				[UIView animateWithDuration:animated ? 0.20f : 0
								 animations:^{
									 
									 _selectedBackgroundLayer.opacity = 0;
								 }
								 completion:^(BOOL finished) {
									 [_selectedBackgroundLayer removeFromSuperlayer];
								 }];
			}
			else {
				_selectedBackgroundLayer.opacity = 0;
				[_selectedBackgroundLayer removeFromSuperlayer];
			}
			
			_label.textColor = [UIColor redColor];
		}	break;
		case ObjectListItemViewStateEditingSelected: {
			_selectedBackgroundLayer.opacity = 0;
			[self.layer insertSublayer:_selectedBackgroundLayer atIndex:0];
			
			if (animated) {
				[UIView animateWithDuration:animated ? 0.20f : 0
								 animations:^{
									 _selectedBackgroundLayer.opacity = 1;
								 }];
			}
			else {
				_selectedBackgroundLayer.opacity = 1;
			}
			
			_label.textColor = [UIColor redColor];
		}	break;
			
		default:
			break;
	}
}

@end
