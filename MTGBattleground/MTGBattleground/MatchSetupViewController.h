//
//  MatchSetupViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ManagableViewController.h"

@class LocalUserSelectionView;

@interface MatchSetupViewController : ManagableViewController

@property (nonatomic) IBOutletCollection(LocalUserSelectionView) NSArray *localUserSelectionViews;
@property (nonatomic) IBOutlet UIButton *startButton;
@property (nonatomic) IBOutlet UITextField *startingLifeTextField;
@property (nonatomic) IBOutlet UISwitch *poisonCounterSwitch;
@property (nonatomic) IBOutlet UISwitch *dynamicCounterSwitch;
@property (nonatomic) IBOutlet UISwitch *turnTrackingSwitch;

@end
