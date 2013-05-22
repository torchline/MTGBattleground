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
	AlertReasonQuit,
	AlertReasonVerifyMatchDraw
} AlertReason;


@class LifeCounterView;


@interface MatchViewController : ManagableViewController

@property (nonatomic) UIButton *quitButton;
@property (nonatomic) UIButton *passButton;
@property (nonatomic) UIButton *undoButton;

@property (nonatomic) NSMutableArray *nameLabels;
@property (nonatomic) NSMutableArray *lifeCounterViews;
@property (nonatomic) NSMutableArray *userIconImageViews;
@property (nonatomic) NSMutableArray *glow1ImageViews;
@property (nonatomic) NSMutableArray *glow2ImageViews;

@end
