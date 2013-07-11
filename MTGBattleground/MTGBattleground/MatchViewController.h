//
//  ViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ManagableViewController.h"

typedef enum : NSUInteger {
	AlertReasonUndo = 1,
	AlertReasonResetTurn,
	AlertReasonQuit,
	AlertReasonVerifyMatchDraw
} AlertReason;


@class LifeCounterView;
@class Match;


@interface MatchViewController : ManagableViewController <UIGestureRecognizerDelegate> {
	BOOL _isInitialized;
	AlertReason _alertReason;
	
	UILongPressGestureRecognizer *_longPressGestureRecognizer;
	Match *_match;
	NSMutableDictionary *_userPositionDictionary;

	UIButton *_quitButton;
	UIButton *_passButton;
	UIButton *_undoButton;
	UIButton *_resetTurnButton;
	
	NSMutableArray *_nameLabels;
	NSMutableArray *_lifeCounterViews;
	NSMutableArray *_userIconImageViews;
	NSMutableArray *_glow1ImageViews;
	NSMutableArray *_glow2ImageViews;
	NSMutableSet *_dynamicCounterViews;
}

@end
