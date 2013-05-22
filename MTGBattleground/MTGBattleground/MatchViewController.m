//
//  ViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchViewController.h"
#import "LifeCounterView.h"
#import <QuartzCore/CALayer.h>
#import "LocalUser.h"
#import "Match.h"
#import "MatchTurn.h"
#import "Database.h"
#import <dispatch/dispatch.h>
#import "Settings.h"
#import "MatchManager.h"
#import "ViewManagerAccess.h"
#import "UserIcon.h"
#import "NSMutableArray+Queueing.h"
#import "UIView+BasicAnimation.h"


@interface MatchViewController () <UIAlertViewDelegate>

@property (nonatomic) BOOL isInitialized;
@property (nonatomic) AlertReason alertReason;
@property (nonatomic) Match *match;
@property (nonatomic) NSMutableArray *localUsers;
@property (nonatomic) NSMutableArray *pendingLocalUsersToKill;
@property (nonatomic) NSMutableDictionary *localUserSlotDictionary;
@property (nonatomic, weak) LocalUser *activeLocalUser;

@end


@implementation MatchViewController

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {	
	for (LocalUser *localUser in self.localUsers) {
		[localUser removeObserver:self forKeyPath:@"state.isDead"];
	}
}


#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		self.presentationStyle = ManagableViewPresentationStylePushFromRight;
		
		self.alertReason = -1;
		self.isInitialized = NO;
		
		self.lifeCounterViews = [[NSMutableArray alloc] initWithCapacity:4];
		self.nameLabels = [[NSMutableArray alloc] initWithCapacity:4];
		self.userIconImageViews = [[NSMutableArray alloc] initWithCapacity:4];
		self.glow1ImageViews = [[NSMutableArray alloc] initWithCapacity:4];
		self.glow2ImageViews = [[NSMutableArray alloc] initWithCapacity:4];
	}
	return self;
}

- (BOOL)viewDidLoadFromViewController:(ManagableViewController *)aViewController {
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	// fetch Match
	self.match = [Database activeMatch];
	NSAssert(self.match, @"No active Match found");
	
	// disable undo button if this is first turn
	MatchTurn *previousMatchTurn = [Database lastMatchTurnForMatch:self.match];
	if (!previousMatchTurn) {
		self.undoButton.enabled = NO;
	}
	
	// fetch users for the Match
	LocalUser *activeLocalUser;
	self.localUsers = [Database localUsersParticipatingInMatch:self.match activeLocalUser:&activeLocalUser];
	NSAssert([self.localUsers count], @"Could not find any LocalUser participants for the active Match");
	NSAssert(activeLocalUser, @"Could not find active user for Match");
	
	// organize LocalUsers for faster access
	self.localUserSlotDictionary = [[NSMutableDictionary alloc] initWithCapacity:[self.localUsers count]];
	for (LocalUser *localUser in self.localUsers) {
		[self.localUserSlotDictionary setObject:localUser forKey:@(localUser.state.userSlot)];
	}

	// create pass button
	if (self.match.enableTurnTracking) {
		UIImage *passButtonImage = [UIImage imageNamed:@"PassButton.png"];
		self.passButton = [UIButton buttonWithType:UIButtonTypeCustom];
		self.passButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 60, 0);
		[self.passButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		self.passButton.adjustsImageWhenHighlighted = NO;
		self.passButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:40];
		[self.passButton setTitle:@"Pass" forState:UIControlStateNormal];
		[self.passButton setBackgroundImage:passButtonImage forState:UIControlStateNormal];
		[self.passButton addTarget:self action:@selector(passButtonPressed) forControlEvents:UIControlEventTouchDown];
		self.passButton.frame = CGRectMake(0, 0, passButtonImage.size.width, passButtonImage.size.height);
		[self.view addSubview:self.passButton];
	}
	
	// create quit button
	self.quitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.quitButton setTitle:@"Quit" forState:UIControlStateNormal];
	[self.quitButton addTarget:self action:@selector(quitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.quitButton.frame = CGRectMake(20, 20, 60, 60);
	[self.view addSubview:self.quitButton];
	
	// create undo button
	//UIImage *undoButtonImage = [UIImage imageNamed:@"UndoButton.png"];
	self.undoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.undoButton setTitle:@"Undo" forState:UIControlStateNormal];
	//[self.undoButton setBackgroundImage:undoButtonImage forState:UIControlStateNormal];
	[self.undoButton addTarget:self action:@selector(undoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.undoButton.frame = CGRectMake(CGRectGetMaxX(self.view.bounds) - 60 - 20, CGRectGetMaxY(self.view.bounds) - 60 - 20, 60, 60);
	[self.view addSubview:self.undoButton];
	
	NSMutableDictionary *userIconIDDictionary = [Database idDictionaryForDatabaseObjects:[Database userIcons]];
	
	UIImage *glow1Image = [UIImage imageNamed:@"RayGlow1.png"];
	UIImage *glow2Image = [UIImage imageNamed:@"RayGlow2.png"];
	
	// create user controls
	for (LocalUser *localUser in self.localUsers) {
		// create life counter
		LifeCounterView *lifeCounterView = [[LifeCounterView alloc] initWithFrame:[self defaultFrameForLifeCounterAtUserSlot:localUser.state.userSlot]];
		lifeCounterView.localUser = localUser;
		lifeCounterView.transform = CGAffineTransformRotate(lifeCounterView.transform, [self rotationAngleForUserSlot:localUser.state.userSlot]);
		[self.lifeCounterViews addObject:lifeCounterView];
		[self.view addSubview:lifeCounterView];
		
		// create glow images
		UIImage *coloredGlow1Image = [self recolorImage:glow1Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow1ImageView = [[UIImageView alloc] initWithImage:coloredGlow1Image];
		glow1ImageView.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(0, 60) size:glow1ImageView.frame.size];
		glow1ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:localUser.state.userSlot]);
		glow1ImageView.alpha = 0.60f;
		[self.glow1ImageViews addObject:glow1ImageView];
		[self.view insertSubview:glow1ImageView belowSubview:lifeCounterView];
		
		UIImage *coloredGlow2Image = [self recolorImage:glow2Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow2ImageView = [[UIImageView alloc] initWithImage:coloredGlow2Image];
		glow2ImageView.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(0, 60) size:glow2ImageView.frame.size];
		glow2ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:localUser.state.userSlot]);
		glow2ImageView.alpha = 0.60f;
		[self.glow2ImageViews addObject:glow2ImageView];
		[self.view insertSubview:glow2ImageView belowSubview:lifeCounterView];
		
		// create icon image views
		UserIcon *userIcon = localUser.userIcon ? localUser.userIcon : [userIconIDDictionary objectForKey:@(localUser.userIconID)];
		if (userIcon) {
			UIImageView *userIconImageView = [[UIImageView alloc] initWithImage:userIcon.image];
			userIconImageView.frame = [self frameForUserSlot:localUser.state.userSlot
									   offsetFromLifeCounter:CGPointMake(130, 80)
														size:CGSizeMake(75, 75)];
			userIconImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:localUser.state.userSlot]);
			[self.userIconImageViews addObject:userIconImageView];
			[self.view addSubview:userIconImageView];
		}
		else {
			NSLog(@"could not find user icon %d", localUser.userIconID);
		}
		
		// create username label
		UILabel *usernameLabel = [[UILabel alloc] init];
		usernameLabel.frame = [self frameForUserSlot:localUser.state.userSlot
							   offsetFromLifeCounter:CGPointMake(-200, 80)
												size:CGSizeMake(200, 30)];
		usernameLabel.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:localUser.state.userSlot]);
		usernameLabel.backgroundColor = [UIColor clearColor];
		usernameLabel.textAlignment = NSTextAlignmentRight;
		usernameLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME size:26];
		usernameLabel.text = localUser.name;
		
		[self.nameLabels addObject:usernameLabel];
		[self.view addSubview:usernameLabel];
		
		// drop some eaves
		[localUser addObserver:self forKeyPath:@"state.isDead" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
	}
	
	// required below because it updates UI assembled above
	self.activeLocalUser = activeLocalUser;
	
	self.isInitialized = YES;
	
	return YES;
}


#pragma mark - User Interaction

- (void)passButtonPressed {
	self.undoButton.enabled = YES;
	
	// kill anybody that needs killing
	BOOL isPromptingPlayersForDraw = ![self killLocalUsersThatShouldBeDead];
	if (isPromptingPlayersForDraw) {
		return;
	}
	
	// store turn and states for all users
	[MatchManager createMatchTurnWithMatch:self.match activeLocalUser:self.activeLocalUser allLocalUsers:self.localUsers];
	
	BOOL isComplete = [self isMatchCompleted];
	if (isComplete) {
		[self matchCompleted];
	}
	else {
		[self switchToNextActiveLocalUser];
	}
}

- (void)quitButtonPressed {
	self.alertReason = AlertReasonQuit;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will destroy all traces of this match."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it to it!", nil];
	
	[alertView show];
}

- (void)undoButtonPressed {
	self.alertReason = AlertReasonUndo;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will revert every player to the state at the last turn."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it!", nil];
	
	[alertView show];
}


#pragma mark - Match Helper

- (void)quitMatch {
	[MatchManager deleteActiveMatch:self.match];
	[Settings setNullValueForKey:SETTINGS_CURRENT_ACTIVE_MATCH_ID];
	
	[[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
}

- (void)restorePreviousUserStates {
	LocalUser *newActiveLocalUser;
	[MatchManager restorePreviousUserStatesForMatch:self.match localUsers:self.localUsers activeLocalUser:&newActiveLocalUser];
	
	self.activeLocalUser = newActiveLocalUser;
	
	// disable undo button if we don't have another previous MatchTurn
	MatchTurn *previousMatchTurn = [Database lastMatchTurnForMatch:self.match];
	if (!previousMatchTurn) {
		self.undoButton.enabled = NO;
	}
}

// returns NO if querying players to verify a Match draw
// returns YES otherwise
- (BOOL)killLocalUsersThatShouldBeDead {
	if (self.match.enableAutoDeath) {
		if (!self.pendingLocalUsersToKill) {
			self.pendingLocalUsersToKill = [[NSMutableArray alloc] initWithCapacity:1];
		}
		else {
			[self.pendingLocalUsersToKill removeAllObjects];
		}
		
		NSUInteger numDeadUsers = 0;
		for (LocalUser *localUser in self.localUsers) {
			if (localUser.state.isDead) { // skip if already dead
				numDeadUsers++;
				continue;
			}
			
			if (localUser.state.life <= 0 || localUser.state.poison >= self.match.poisonToDie) { // death conditions
				[self.pendingLocalUsersToKill addObject:localUser];
			}
		}
		
		if ([self.pendingLocalUsersToKill count] > 0) {
			if ([self.pendingLocalUsersToKill count] + numDeadUsers >= [self.localUsers count]) { // if every user will end up dead
				self.alertReason = AlertReasonVerifyMatchDraw;
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Draw?!"
																	message:@"Verify that there is no winner to this game we call Magic."
																   delegate:self
														  cancelButtonTitle:@"Cancel"
														  otherButtonTitles:@"It's a draw", nil];
				
				[alertView show];
				return NO;
			}
			else {
				[self killPendingLocalUsersToKill];
			}
		}
	}
	
	return YES;
}

- (LocalUser *)nextActiveLocalUser {
	NSUInteger checkCount = 0;
	NSUInteger maxCheckCount = [self.localUsers count];
	LocalUser *nextActiveLocalUser = [self.localUsers objectAfterObject:self.activeLocalUser];
	while (nextActiveLocalUser.state.isDead && checkCount < maxCheckCount) {
		nextActiveLocalUser = [self.localUsers objectAfterObject:nextActiveLocalUser];
		checkCount++;
	}
	
	if (checkCount == maxCheckCount) {
		nextActiveLocalUser = nil;
	}
		
	return nextActiveLocalUser;
}

- (void)switchToNextActiveLocalUser {
	LocalUser *nextActiveLocalUser = [self nextActiveLocalUser];
	NSAssert(nextActiveLocalUser, @"Could not find next active user after searching the entire list");
	
	self.activeLocalUser = nextActiveLocalUser;
}

- (BOOL)isMatchCompleted {
	NSUInteger numUsersAlive = 0;
	for (LocalUser *localUser in self.localUsers) {
		if (!localUser.state.isDead) {
			numUsersAlive++;
		}
	}
	
	return numUsersAlive <= 1;
}

- (void)localUserDied:(LocalUser *)localUser {
	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserSlot:localUser.state.userSlot];
	UIImageView *userIconImageView = [self userIconImageViewForLocalUser:localUser];
	UILabel *nameLabel = [self nameLabelForLocalUser:localUser];
	
	[UIView animateWithDuration:(self.isInitialized ? 0.40f : 0)
					 animations:^{
						 lifeCounterView.transform = CGAffineTransformScale(lifeCounterView.transform, 0.001, 0.001);
						 userIconImageView.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(130, 200) size:userIconImageView.frame.size];
						 nameLabel.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(-200, 200) size:nameLabel.frame.size];
					 }
					 completion:^(BOOL finished) {
						 
					 }];
}
	 
- (void)localUserResurrected:(LocalUser *)localUser {
	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserSlot:localUser.state.userSlot];
	UIImageView *userIconImageView = [self userIconImageViewForLocalUser:localUser];
	UILabel *nameLabel = [self nameLabelForLocalUser:localUser];
	
	[UIView animateWithDuration:0.40f
					 animations:^{
						 lifeCounterView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:localUser.state.userSlot]);
						 userIconImageView.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(130, 80) size:userIconImageView.frame.size];
						 nameLabel.frame = [self frameForUserSlot:localUser.state.userSlot offsetFromLifeCounter:CGPointMake(-200, 80) size:nameLabel.frame.size];
					 }
					 completion:^(BOOL finished) {
						 
					 }];
}

- (void)matchCompleted {
	LocalUser *localUserWinner;
	for (LocalUser *localUser in self.localUsers) {
		if (!localUser.state.isDead) {
			localUserWinner = localUser;
			break;
		}
	}
			
	[UIView animateWithDuration:0.40f
					 animations:^{
						 self.passButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
					 }
					 completion:^(BOOL finished) {
						 [UIView animateWithDuration:0.40f
										  animations:^{
											  self.passButton.transform = CGAffineTransformScale(self.passButton.transform, 0.001, 0.001);
										  }
										  completion:^(BOOL finished) {
											  
										  }];
					 }];
	
	[self disableInterfaceForAnimation:YES];
	
	[MatchManager matchCompleted:self.match localUsers:self.localUsers];

	if (localUserWinner) {
		LifeCounterView *winnerLifeCounterView = [self lifeCounterViewForUserSlot:localUserWinner.state.userSlot];
		[UIView animateWithDuration:1.20f
						 animations:^{
							 winnerLifeCounterView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
							 winnerLifeCounterView.transform = CGAffineTransformScale(winnerLifeCounterView.transform, 1.5, 1.5);
						 }
						 completion:^(BOOL finished) {
							 double delayInSeconds = 2.0;
							 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
							 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
								 [[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
							 });
						 }];
	}
	else {
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
		});
	}
}


#pragma mark - Helper

- (void)killPendingLocalUsersToKill {
	for (LocalUser *localUserToKill in self.pendingLocalUsersToKill) {
		localUserToKill.state.isDead = YES;
	}
	
	[self.pendingLocalUsersToKill removeAllObjects];
}

- (UIImage *)recolorImage:(UIImage *)image color:(UIColor *)color {
	CGImageRef imageRef = image.CGImage;
	CGColorRef colorRef = color.CGColor;
	
	CGRect contextFrame = CGRectMake(0, 0, image.size.width, image.size.height);
	
	CGContextRef context = CGBitmapContextCreate(NULL,
                                                 image.size.width,
                                                 image.size.height,
												 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 CGImageGetColorSpace(imageRef),
                                                 kCGImageAlphaPremultipliedLast);
		
	CGContextSetFillColorWithColor(context, colorRef);

	CGContextClipToMask(context, contextFrame, imageRef);
	CGContextSetBlendMode(context, kCGBlendModeColor);
	CGContextFillRect(context, contextFrame);
	CGContextDrawImage(context, contextFrame, imageRef);
	
	CGImageRef coloredImage = CGBitmapContextCreateImage(context);
	
	CGContextRelease(context);
	
	return [UIImage imageWithCGImage:coloredImage];
}

- (CGFloat)rotationAngleForUserSlot:(UserSlot)userSlot {
	NSAssert(userSlot > 0 && userSlot <= 4, @"UserSlot supplied is out of range (%d)", userSlot);

	switch (userSlot) {
		case UserSlotSouth:
			return 0;
			break;
		case UserSlotWest:
			return M_PI_2;
			break;
		case UserSlotNorth:
			return M_PI;
			break;
		case UserSlotEast:
			return -M_PI_2;
			break;
		default:
			return 0;
			break;
	}
}

- (CGRect)frameForUserSlot:(UserSlot)userSlot
 offsetFromLifeCounter:(CGPoint)offset
					size:(CGSize)size {
	NSAssert(userSlot > 0 && userSlot <= 4, @"UserSlot supplied is out of range (%d)", userSlot);

	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserSlot:userSlot];
	
	switch (userSlot) {
		case UserSlotSouth: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 + offset.x,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 + offset.y,
							  size.width,
							  size.height);
		}	break;
		case UserSlotWest: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 - offset.y,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 + offset.x,
							  size.width,
							  size.height);
		}	break;
		case UserSlotNorth: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 - offset.x,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 - offset.y,
							  size.width,
							  size.height);
		}	break;
		case UserSlotEast: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 + offset.y,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 - offset.x,
							  size.width,
							  size.height);
		}	break;
			
		default:
			return CGRectNull;
			break;
	}
}

- (CGRect)defaultFrameForLifeCounterAtUserSlot:(UserSlot)userSlot {
	NSAssert(userSlot > 0 && userSlot <= 4, @"UserSlot supplied is out of range (%d)", userSlot);
	
	CGSize defaultSize = CGSizeMake(200, 200);
	
	switch (userSlot) {
		case UserSlotSouth: {
			return CGRectMake(CGRectGetMidX(self.view.bounds) - defaultSize.width/2,
							  CGRectGetMaxY(self.view.bounds) - defaultSize.height - 20,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserSlotWest: {
			return CGRectMake(20,
							  CGRectGetMidY(self.view.bounds) - defaultSize.height/2,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserSlotNorth: {
			return CGRectMake(CGRectGetMidX(self.view.bounds) - defaultSize.width/2,
							  20,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserSlotEast: {
			return CGRectMake(CGRectGetMaxX(self.view.bounds) - defaultSize.width - 20,
							  CGRectGetMidY(self.view.bounds) - defaultSize.height/2,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
			
		default:
			return CGRectNull;
			break;
	}
}

- (LifeCounterView *)lifeCounterViewForUserSlot:(UserSlot)userSlot {
	NSAssert([self.lifeCounterViews count] > 0, @"There are no name labels");

	LocalUser *localUser = [self.localUserSlotDictionary objectForKey:@(userSlot)];
	NSAssert(localUser, @"There is no LocalUser at slot %d", userSlot);
	
	NSUInteger localUserIndex = [self.localUsers indexOfObject:localUser];
	NSAssert(localUser, @"That user is not one of the current users", userSlot);
	
	return [self.lifeCounterViews objectAtIndex:localUserIndex];
}

- (UIImageView *)userIconImageViewForLocalUser:(LocalUser *)localUser {
	NSAssert([self.userIconImageViews count] > 0, @"There are no name labels");

	NSUInteger localUserIndex = [self.localUsers indexOfObject:localUser];
	NSAssert(localUser, @"That user is not one of the current users");
	
	return [self.userIconImageViews objectAtIndex:localUserIndex];
}

- (UILabel *)nameLabelForLocalUser:(LocalUser *)localUser {
	NSAssert([self.nameLabels count] > 0, @"There are no name labels");
	
	NSUInteger localUserIndex = [self.localUsers indexOfObject:localUser];
	NSAssert(localUser, @"That user is not one of the current users");
	
	return [self.nameLabels objectAtIndex:localUserIndex];
}

- (void)disableInterfaceForAnimation:(BOOL)disable {
	self.view.userInteractionEnabled = !disable;
}


#pragma mark - Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch (self.alertReason) {
		case AlertReasonUndo:
			switch (buttonIndex) {
				case 1:
					[self restorePreviousUserStates];
					break;
			}
			break;
		case AlertReasonQuit:
			switch (buttonIndex) {
				case 1:
					[self quitMatch];
					break;
			}
			break;
		case AlertReasonVerifyMatchDraw:
			switch (buttonIndex) {
				case 0:
					[self.pendingLocalUsersToKill removeAllObjects];
					break;
				case 1:
					[self killPendingLocalUsersToKill];
					
					BOOL isComplete = [self isMatchCompleted];
					if (isComplete) {
						[self matchCompleted];
					}
					else {
						[self switchToNextActiveLocalUser];
					}
					break;
			}
			break;
			
		default:
			NSAssert(NO, @"AlertReason is invalid: %d", self.alertReason);
			break;
	}
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([object isKindOfClass:[LocalUser class]] && [keyPath isEqualToString:@"state.isDead"]) {
		LocalUser *localUser = (LocalUser *)object;
				
		BOOL wasDeadBeforeChange = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
		BOOL isDeadNow = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ((!wasDeadBeforeChange || !self.isInitialized) && isDeadNow) {
			[Database updateCurrentUserStateForActiveMatch:localUser.state];
			[self localUserDied:localUser];
		}
		else if (wasDeadBeforeChange && !isDeadNow) {
			[Database updateCurrentUserStateForActiveMatch:localUser.state];
			[self localUserResurrected:localUser];
		}
	}
}


#pragma mark - Getter / Setter

- (void)setActiveLocalUser:(LocalUser *)activeLocalUser {
	BOOL shouldAnimatePassButton = _activeLocalUser != nil;
	
	_activeLocalUser = activeLocalUser;
	
	if (shouldAnimatePassButton) {
		[UIView animateWithDuration:0.30f
						 animations:^{
							 self.passButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
						 }
						 completion:^(BOOL finished) {
							 [UIView animateWithDuration:0.30f
											  animations:^{
												  self.passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:activeLocalUser.state.userSlot]);
											  }
											  completion:^(BOOL finished) {
												  [UIView animateWithDuration:0.30f
																   animations:^{
																	  self.passButton.frame = [self frameForUserSlot:activeLocalUser.state.userSlot offsetFromLifeCounter:CGPointMake(0, -136) size:self.passButton.frame.size]; 
																   }];
											  }];
						 }];
	}
	else {
		self.passButton.frame = [self frameForUserSlot:activeLocalUser.state.userSlot offsetFromLifeCounter:CGPointMake(0, -136) size:self.passButton.frame.size];
		self.passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:activeLocalUser.state.userSlot]);
	}
	
	/*
	[self.passButton hideByShrinkingForDuration:0.30f
									 completion:^(BOOL finished) {
										 // move turn button to this user
										 self.passButton.frame = [self frameForUserSlot:activeLocalUser.state.userSlot offsetFromLifeCounter:CGPointMake(0, -136) size:self.passButton.frame.size];
										 self.passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserSlot:activeLocalUser.state.userSlot]);
										 
										 [self.passButton showByExpandingForDuration:0.30f completion:nil];
									 }];
	 */
}

@end
