//
//  LifeCounterView.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface LifeCounterView : UIView {
	BOOL _isSetup;
	NSUInteger _numSegmentsPerCircle;
	UIImage *_segmentImage;
	NSInteger _lifeAtLastCommit;
	
	// UI
	NSMutableArray *_segmentImageViews;
	UILabel *_lifeLabel;
	UIButton *_upButton;
	UIButton *_downButton;
}

@property (nonatomic) User *user;
@property (nonatomic) BOOL enabled;

- (void)commitLifeChange;

@end
