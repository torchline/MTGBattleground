//
//  MatchSetupViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchSetupViewController.h"
#import "Database.h"
#import "LocalUserListViewController.h"
#import "LocalUser.h"
#import "LocalUserSelectionView.h"
#import "UserIconListViewController.h"
#import "UserIcon.h"
#import "NSMutableArray+Queueing.h"
#import "NSMutableDictionary+Random.h"
#import "ViewManagerAccess.h"
#import "Settings.h"
#import "MatchManager.h"
#import "Match.h"

@interface MatchSetupViewController () <UIPopoverControllerDelegate, LocalUserListViewControllerDelegate, LocalUserSelectionViewDelegate, UserIconListViewDelegate, UITextFieldDelegate>

@property (nonatomic) UIPopoverController *myPopoverController;
@property (nonatomic) LocalUserListViewController *localUserListViewController;
@property (nonatomic) UserIconListViewController *userIconListViewController;
@property (nonatomic, weak) LocalUserSelectionView *activeLocalUserSelectionView;

@property (nonatomic) NSMutableDictionary *userIconIDDictionary;

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

- (void)viewDidLoad {
    [super viewDidLoad];
		
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	self.startButton.enabled = NO;
	
	self.userIconIDDictionary = [Database idDictionaryForDatabaseObjects:[Database userIcons]];
	
	// load settings from db
	NSString *startingLifeString = [Settings stringForKey:SETTINGS_MATCH_STARTING_LIFE];
	self.startingLifeTextField.text = startingLifeString;
	
	BOOL enablePoisonCounter = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_POISON_COUNTER] boolValue];
	[self.poisonCounterSwitch setOn:enablePoisonCounter];
	
	BOOL enableDynamicCounters = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_DYNAMIC_COUNTERS] boolValue];
	[self.dynamicCounterSwitch setOn:enableDynamicCounters];

	BOOL enableTurnTracking = [[Settings stringForKey:SETTINGS_MATCH_ENABLE_TURN_TRACKING] boolValue];
	[self.turnTrackingSwitch setOn:enableTurnTracking];
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
	// get assigned LocalUsers and assign their active state values for the upcoming match
	NSMutableArray *localUsers = [[NSMutableArray alloc] initWithCapacity:4];
	NSUInteger i = 0;
	for (LocalUserSelectionView *selectionView in self.localUserSelectionViews) {
		if (selectionView.localUser) {
			selectionView.localUser.state = [[UserState alloc] init];
			selectionView.localUser.state.userSlot = i + 1;
			
			[localUsers addObject:selectionView.localUser];
		}
		
		i++;
	}
	
	// create Match
	Match *match = [MatchManager createMatchWithLocalUsers:localUsers
											  startingLife:[self.startingLifeTextField.text integerValue]
											 poisonCounter:self.poisonCounterSwitch.isOn
										   dynamicCounters:self.dynamicCounterSwitch.isOn
												turnTracking:self.turnTrackingSwitch.isOn];
	
	[Settings setStringAsData:match.ID forKey:SETTINGS_CURRENT_ACTIVE_MATCH_ID];
	
	[[ViewManager sharedInstance] switchToView:[MatchViewController class]];
}


#pragma mark - Delegate

- (void)localUserSelectionViewDidRequestNewName:(LocalUserSelectionView *)localUserSelectionView {
	self.activeLocalUserSelectionView = localUserSelectionView;
	
	if (!self.localUserListViewController) {
		self.localUserListViewController = [[LocalUserListViewController alloc] initWithNibName:nil bundle:nil];
		self.localUserListViewController.delegate = self;
	}
	
	self.myPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.localUserListViewController];
	self.myPopoverController.delegate = self;
	self.myPopoverController.popoverContentSize = self.localUserListViewController.view.frame.size;
	
	[self.myPopoverController presentPopoverFromRect:[self.view convertRect:localUserSelectionView.nameButton.frame fromView:localUserSelectionView.nameButton.superview]
											  inView:self.view
							permittedArrowDirections:UIPopoverArrowDirectionLeft
											animated:YES];
}

- (void)localUserSelectionViewDidRequestNewIcon:(LocalUserSelectionView *)localUserSelectionView {
	self.activeLocalUserSelectionView = localUserSelectionView;
	
	if (!self.userIconListViewController) {
		self.userIconListViewController = [[UserIconListViewController alloc] initWithNibName:nil bundle:nil];
		self.userIconListViewController.delegate = self;
	}
	
	self.myPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.userIconListViewController];
	self.myPopoverController.delegate = self;
	self.myPopoverController.popoverContentSize = self.userIconListViewController.view.frame.size;

	[self.myPopoverController presentPopoverFromRect:[self.view convertRect:localUserSelectionView.iconButton.frame fromView:localUserSelectionView.iconButton.superview]
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


- (void)localUserListViewControllerDidPickUser:(LocalUser *)localUser {
	if (localUser.userIconID > 0) {
		localUser.userIcon = [self.userIconIDDictionary objectForKey:[localUser identifiableID]];
	}
	else {
		UserIcon *randomUserIcon = [self.userIconIDDictionary randomObject];
		
		localUser.userIconID = randomUserIcon.ID;
		localUser.userIcon = randomUserIcon;
		
		[Database updateLocalUser:localUser];
	}
	
	self.activeLocalUserSelectionView.localUser = localUser;
	
	[self.myPopoverController dismissPopoverAnimated:YES];
	
	NSUInteger numSelectedUsers = 0;
	for (LocalUserSelectionView *selectionView in self.localUserSelectionViews) {
		if (selectionView.localUser) {
			numSelectedUsers++;
		}
	}
	
	self.startButton.enabled = numSelectedUsers >= 2;
}

- (void)userIconListViewControllerDidPickUserIcon:(UserIcon *)userIcon {
	self.activeLocalUserSelectionView.localUser.userIcon = userIcon;

	[self.myPopoverController dismissPopoverAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {	
	return [string length] == 0 || [string integerValue] > 0 || [string isEqualToString:@"0"];
}


@end
