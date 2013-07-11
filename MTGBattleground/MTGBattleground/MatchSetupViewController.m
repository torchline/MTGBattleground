//
//  MatchSetupViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchSetupViewController.h"

#import "ViewManagerAccess.h"
#import "Settings.h"
#import "UserService.h"
#import "MatchManager.h"
#import "NSMutableDictionary+Random.h"

#import "UserListViewController.h"
#import "UserIconListViewController.h"

#import "UserSelectionView.h"

#import "Match.h"
#import "MatchService.h"
#import "User+Runtime.h"
#import "UserIcon.h"


@interface MatchSetupViewController () <UIPopoverControllerDelegate, UserListViewControllerDelegate, UserSelectionViewDelegate, UserIconListViewDelegate, UITextFieldDelegate>

@end


@implementation MatchSetupViewController

#pragma mark - System

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}


#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_presentationStyle = ManagableViewPresentationStyleFadeIn;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	NSUInteger numberOfMatches = [MatchService numberOfMatches];
	
	_startButton.enabled = NO;
	_historyButton.enabled = numberOfMatches > 0;
	
	_userIconDictionary = [UserService userIconDictionary];
	
	// load settings from db
	NSString *startingLifeString = [Settings stringForKey:SETTINGS_MATCH_STARTING_LIFE];
	_startingLifeTextField.text = startingLifeString;
	
	BOOL enablePoisonCounter = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_POISON_COUNTER] boolValue];
	[_poisonCounterSwitch setOn:enablePoisonCounter];
	
	BOOL enableDynamicCounters = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS] boolValue];
	[_dynamicCounterSwitch setOn:enableDynamicCounters];

	BOOL enableTurnTracking = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_TURN_TRACKING] boolValue];
	[_turnTrackingSwitch setOn:enableTurnTracking];
}


#pragma mark - Helper

- (void)createAndStartMatch {
	// get assigned Users and assign their active state values for the upcoming match
	NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:4];
	NSMutableArray *userPositions = [[NSMutableArray alloc] initWithCapacity:4];
	
	NSUInteger i = 0;
	for (UserSelectionView *selectionView in _userSelectionViews) {
		User *user = selectionView.user;
		
		if (user) {
			[users addObject:user];
			[userPositions addObject:@(i + 1)];
			
			user.numTimesUsed++;
			user.lastTimeUsed = [NSDate date];
			[UserService updateUser:user];
		}
		
		i++;
	}
	
	Match *match = [MatchManager createMatchWithUsers:users
										userPositions:userPositions
										 startingLife:[_startingLifeTextField.text integerValue]
										  poisonToDie:10
										poisonCounter:_poisonCounterSwitch.isOn
									  dynamicCounters:_dynamicCounterSwitch.isOn
										 turnTracking:_turnTrackingSwitch.isOn
											autoDeath:YES
									  damageTargeting:NO];
	
	[MatchManager setActiveMatch:match];
	
	[[ViewManager sharedInstance] switchToView:[MatchViewController class] options:@{VIEW_OPTION_MATCH : match}];
}


#pragma mark - User Interaction

- (IBAction)startingLifeTextFieldChanged {
	_startingLifeTextField.text = [[NSString alloc] initWithFormat:@"%d", MIN(999, MAX(1, [_startingLifeTextField.text integerValue]))];
	[Settings setString:_startingLifeTextField.text forKey:SETTINGS_MATCH_STARTING_LIFE];
}

- (IBAction)poisonCounterSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", _poisonCounterSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_POISON_COUNTER];
}

- (IBAction)dynamicCounterSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", _dynamicCounterSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS];
}

- (IBAction)turnTrackingSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", _turnTrackingSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_TURN_TRACKING];
}

- (IBAction)startButtonPressed {
	[self createAndStartMatch];
}

- (IBAction)historyButtonPressed {
	[[ViewManager sharedInstance] switchToView:[MatchHistoryViewController class]];
}

#pragma mark - Delegate

- (void)userSelectionViewDidRequestNewName:(UserSelectionView *)userSelectionView {
	_activeUserSelectionView = userSelectionView;
	
	if (!_userListViewController) {
		_userListViewController = [UserListViewController new];
		_userListViewController.delegate = self;
	}
	
	_myPopoverController = [[UIPopoverController alloc] initWithContentViewController:_userListViewController];
	_myPopoverController.delegate = self;
	_myPopoverController.popoverContentSize = _userListViewController.view.frame.size;
	
	CGRect userSelectionViewRect = [self.view convertRect:userSelectionView.nameButton.frame fromView:userSelectionView.nameButton.superview];
	
	[_myPopoverController presentPopoverFromRect:userSelectionViewRect
										  inView:self.view
						permittedArrowDirections:UIPopoverArrowDirectionLeft
										animated:YES];
}

- (void)userSelectionViewDidRequestNewIcon:(UserSelectionView *)userSelectionView {
	_activeUserSelectionView = userSelectionView;
	
	if (!_userIconListViewController) {
		_userIconListViewController = [UserIconListViewController new];
		_userIconListViewController.delegate = self;
	}
	
	_myPopoverController = [[UIPopoverController alloc] initWithContentViewController:_userIconListViewController];
	_myPopoverController.delegate = self;
	_myPopoverController.popoverContentSize = _userIconListViewController.view.frame.size;

	[_myPopoverController presentPopoverFromRect:[self.view convertRect:userSelectionView.iconButton.frame fromView:userSelectionView.iconButton.superview]
										  inView:self.view
						permittedArrowDirections:UIPopoverArrowDirectionLeft
										animated:YES];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	_myPopoverController = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
	return YES;
}


- (void)userListViewController:(UserListViewController *)controller didPickUser:(User *)user {
	if ([controller isEqual:_userListViewController]) {
		if (user.userIconID > 0) {
			if (!user.icon) {
				user.icon = [_userIconDictionary objectForKey:@(user.userIconID)];
			}
		}
		else {
			UserIcon *randomUserIcon = [_userIconDictionary randomObject];
			
			user.userIconID = randomUserIcon.ID;
			user.icon = randomUserIcon;
			
			[UserService updateUser:user];
		}
		
		_activeUserSelectionView.user = user;
		
		[_myPopoverController dismissPopoverAnimated:YES];
		
		NSUInteger numSelectedUsers = 0;
		for (UserSelectionView *selectionView in _userSelectionViews) {
			if (selectionView.user) {
				numSelectedUsers++;
			}
		}
		
		_startButton.enabled = numSelectedUsers >= 2;
	}
}

- (NSArray *)userListViewControllerDisallowedUsers:(UserListViewController *)controller {
	return [_userSelectionViews valueForKey:@"user"];
}

- (void)userIconListViewControllerDidPickUserIcon:(UserIcon *)userIcon {
	User *user = _activeUserSelectionView.user;
	
	user.userIconID = userIcon.ID;
	user.icon = userIcon;
	[UserService updateUser:user];

	[_myPopoverController dismissPopoverAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {	
	return [string length] == 0 || [string integerValue] > 0 || [string isEqualToString:@"0"];
}


@end
