//
//  MatchSetupViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ManagableViewController.h"


@class UserListViewController;
@class UserIconListViewController;
@class UserSelectionView;


@interface MatchSetupViewController : ManagableViewController {
	UIPopoverController *_myPopoverController;
	UserListViewController *_userListViewController;
	UserIconListViewController *_userIconListViewController;
	UserSelectionView *_activeUserSelectionView;
	
	NSMutableDictionary *_userIconDictionary;
}

@property (nonatomic) IBOutletCollection(UserSelectionView) NSArray *userSelectionViews;
@property (nonatomic) IBOutlet UIButton *startButton;
@property (nonatomic) IBOutlet UIButton *historyButton;
@property (nonatomic) IBOutlet UITextField *startingLifeTextField;
@property (nonatomic) IBOutlet UISwitch *poisonCounterSwitch;
@property (nonatomic) IBOutlet UISwitch *dynamicCounterSwitch;
@property (nonatomic) IBOutlet UISwitch *turnTrackingSwitch;

@end
