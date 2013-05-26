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
#import "User+Runtime.h"
#import "UserIcon.h"


@interface MatchSetupViewController () <UIPopoverControllerDelegate, UserListViewControllerDelegate, UserSelectionViewDelegate, UserIconListViewDelegate, UITextFieldDelegate>

@property (nonatomic) UIPopoverController *myPopoverController;
@property (nonatomic) UserListViewController *userListViewController;
@property (nonatomic) UserIconListViewController *userIconListViewController;
@property (nonatomic, weak) UserSelectionView *activeUserSelectionView;

@property (nonatomic) NSMutableDictionary *userIconDictionary;

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
		self.presentationStyle = ManagableViewPresentationStyleFadeIn;
	}
	return self;
}

- (BOOL)viewDidLoadFromViewController:(ManagableViewController *)aViewController {
    [super viewDidLoad];
		
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	self.startButton.enabled = NO;
	
	self.userIconDictionary = [UserService userIconDictionary];
	
	// load settings from db
	NSString *startingLifeString = [Settings stringForKey:SETTINGS_MATCH_STARTING_LIFE];
	self.startingLifeTextField.text = startingLifeString;
	
	BOOL enablePoisonCounter = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_POISON_COUNTER] boolValue];
	[self.poisonCounterSwitch setOn:enablePoisonCounter];
	
	BOOL enableDynamicCounters = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS] boolValue];
	[self.dynamicCounterSwitch setOn:enableDynamicCounters];

	BOOL enableTurnTracking = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_TURN_TRACKING] boolValue];
	[self.turnTrackingSwitch setOn:enableTurnTracking];
	
	return YES;
}


#pragma mark - User Interaction

- (IBAction)startingLifeTextFieldChanged {
	self.startingLifeTextField.text = [[NSString alloc] initWithFormat:@"%d", MAX(1, [self.startingLifeTextField.text integerValue])];
	[Settings setString:self.startingLifeTextField.text forKey:SETTINGS_MATCH_STARTING_LIFE];
}

- (IBAction)poisonCounterSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", self.poisonCounterSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_POISON_COUNTER];
}

- (IBAction)dynamicCounterSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", self.dynamicCounterSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS];
}

- (IBAction)turnTrackingSwitchChanged {
	[Settings setString:[[NSString alloc] initWithFormat:@"%d", self.turnTrackingSwitch.isOn] forKey:SETTINGS_MATCH_ENABLE_TURN_TRACKING];
}

- (IBAction)startButtonPressed {	
	// get assigned Users and assign their active state values for the upcoming match
	NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:4];
	NSUInteger i = 0;
	for (UserSelectionView *selectionView in self.userSelectionViews) {
		if (selectionView.user) {
			
			[users addObject:selectionView.user];
			
			selectionView.user.lastTimeUsed = [NSDate date];
			[UserService updateUser:selectionView.user];
		}
		
		i++;
	}
	
	Match *match = [MatchManager createMatchWithUsers:users
										 startingLife:[self.startingLifeTextField.text integerValue]
										  poisonToDie:10
										poisonCounter:self.poisonCounterSwitch.isOn
									  dynamicCounters:self.dynamicCounterSwitch.isOn
										 turnTracking:self.turnTrackingSwitch.isOn
											autoDeath:YES];
		
	[MatchManager setActiveMatch:match];
	
	[[ViewManager sharedInstance] switchToView:[MatchViewController class] options:@{VIEW_OPTION_MATCH : match}];
}


#pragma mark - Delegate

- (void)userSelectionViewDidRequestNewName:(UserSelectionView *)userSelectionView {
	self.activeUserSelectionView = userSelectionView;
	
	if (!self.userListViewController) {
		self.userListViewController = [[UserListViewController alloc] initWithNibName:nil bundle:nil];
		self.userListViewController.delegate = self;
	}
	
	self.myPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.userListViewController];
	self.myPopoverController.delegate = self;
	self.myPopoverController.popoverContentSize = self.userListViewController.view.frame.size;
	
	[self.myPopoverController presentPopoverFromRect:[self.view convertRect:userSelectionView.nameButton.frame fromView:userSelectionView.nameButton.superview]
											  inView:self.view
							permittedArrowDirections:UIPopoverArrowDirectionLeft
											animated:YES];
}

- (void)userSelectionViewDidRequestNewIcon:(UserSelectionView *)userSelectionView {
	self.activeUserSelectionView = userSelectionView;
	
	if (!self.userIconListViewController) {
		self.userIconListViewController = [[UserIconListViewController alloc] initWithNibName:nil bundle:nil];
		self.userIconListViewController.delegate = self;
	}
	
	self.myPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.userIconListViewController];
	self.myPopoverController.delegate = self;
	self.myPopoverController.popoverContentSize = self.userIconListViewController.view.frame.size;

	[self.myPopoverController presentPopoverFromRect:[self.view convertRect:userSelectionView.iconButton.frame fromView:userSelectionView.iconButton.superview]
											  inView:self.view
							permittedArrowDirections:UIPopoverArrowDirectionLeft
											animated:YES];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	self.myPopoverController = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
	return YES;
}


- (void)userListViewControllerDidPickUser:(User *)user {
	if (user.userIconID > 0) {
		user.icon = [self.userIconDictionary objectForKey:@(user.userIconID)];
	}
	else {
		UserIcon *randomUserIcon = [self.userIconDictionary randomObject];
		
		user.userIconID = randomUserIcon.ID;
		user.icon = randomUserIcon;
		
		[UserService updateUser:user];
	}
	
	self.activeUserSelectionView.user = user;
	
	[self.myPopoverController dismissPopoverAnimated:YES];
	
	NSUInteger numSelectedUsers = 0;
	for (UserSelectionView *selectionView in self.userSelectionViews) {
		if (selectionView.user) {
			numSelectedUsers++;
		}
	}
	
	self.startButton.enabled = numSelectedUsers >= 2;
}

- (void)userIconListViewControllerDidPickUserIcon:(UserIcon *)userIcon {
	self.activeUserSelectionView.user.icon = userIcon;

	[self.myPopoverController dismissPopoverAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {	
	return [string length] == 0 || [string integerValue] > 0 || [string isEqualToString:@"0"];
}


@end
