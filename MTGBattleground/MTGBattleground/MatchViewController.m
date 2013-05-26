//
//  ViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchViewController.h"

#import <QuartzCore/CALayer.h>
#import <dispatch/dispatch.h>
#import "UIView+BasicAnimation.h"
#import "ViewManagerAccess.h"
#import "Settings.h"
#import "MatchManager.h"
#import "UserService.h"
#import "MatchService.h"

#import "LifeCounterView.h"

#import "User+Runtime.h"
#import "Match+Runtime.h"
#import "MatchTurn+Runtime.h"
#import "UserIcon.h"

@interface MatchViewController () <UIAlertViewDelegate>

@property (nonatomic) BOOL isInitialized;
@property (nonatomic) AlertReason alertReason;
@property (nonatomic) Match *match;
@property (nonatomic) NSMutableDictionary *userPositionDictionary;

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
	for (User *user in self.match.users) {
		[user removeObserver:self forKeyPath:@"state.poison"];
		[user removeObserver:self forKeyPath:@"state.life"];
		[user removeObserver:self forKeyPath:@"state.isDead"];
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
	self.match = [self.viewOptions objectForKey:VIEW_OPTION_MATCH];
	NSAssert(self.match, @"No active Match found");
	
	self.match.startTime = [NSDate date];
	[MatchService updateMatch:self.match];
	
	// disable undo button if this is first turn
	if (self.match.currentTurn.turnNumber == 1) {
		self.undoButton.enabled = NO;
	}
		
	// organize Users for faster access
	self.userPositionDictionary = [[NSMutableDictionary alloc] initWithCapacity:[self.match.users count]];
	for (User *user in self.match.users) {
		[self.userPositionDictionary setObject:user forKey:@(user.meta.userPosition)];
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
	self.undoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.undoButton setTitle:@"Back" forState:UIControlStateNormal];
	[self.undoButton addTarget:self action:@selector(undoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.undoButton.frame = CGRectMake(CGRectGetMaxX(self.view.bounds) - 60 - 20, CGRectGetMaxY(self.view.bounds) - 60 - 20, 60, 60);
	[self.view addSubview:self.undoButton];
	
	// create reset turn button
	self.resetTurnButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[self.resetTurnButton setTitle:@"Reset" forState:UIControlStateNormal];
	[self.resetTurnButton addTarget:self action:@selector(resetTurnButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	self.resetTurnButton.frame = CGRectOffset(self.undoButton.frame, 0, -80);
	[self.view addSubview:self.resetTurnButton];
	
	NSMutableDictionary *userIconDictionary = [UserService userIconDictionary];
	
	UIImage *glow1Image = [UIImage imageNamed:@"RayGlow1.png"];
	UIImage *glow2Image = [UIImage imageNamed:@"RayGlow2.png"];
	
	// create user controls
	for (User *user in self.match.users) {
		// create life counter
		LifeCounterView *lifeCounterView = [[LifeCounterView alloc] initWithFrame:[self defaultFrameForLifeCounterAtUserPosition:user.meta.userPosition]];
		lifeCounterView.user = user;
		lifeCounterView.transform = CGAffineTransformRotate(lifeCounterView.transform, [self rotationAngleForUserPosition:user.meta.userPosition]);
		[self.lifeCounterViews addObject:lifeCounterView];
		[self.view addSubview:lifeCounterView];
		
		// create glow images
		UIImage *coloredGlow1Image = [self recolorImage:glow1Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow1ImageView = [[UIImageView alloc] initWithImage:coloredGlow1Image];
		glow1ImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, 60) size:glow1ImageView.frame.size];
		glow1ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		glow1ImageView.alpha = 0.60f;
		[self.glow1ImageViews addObject:glow1ImageView];
		[self.view insertSubview:glow1ImageView belowSubview:lifeCounterView];
		
		UIImage *coloredGlow2Image = [self recolorImage:glow2Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow2ImageView = [[UIImageView alloc] initWithImage:coloredGlow2Image];
		glow2ImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, 60) size:glow2ImageView.frame.size];
		glow2ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		glow2ImageView.alpha = 0.60f;
		[self.glow2ImageViews addObject:glow2ImageView];
		[self.view insertSubview:glow2ImageView belowSubview:lifeCounterView];
		
		// create icon image views
		UserIcon *userIcon = user.icon ? user.icon : [userIconDictionary objectForKey:@(user.userIconID)];
		if (userIcon) {
			UIImageView *userIconImageView = [[UIImageView alloc] initWithImage:userIcon.image];
			userIconImageView.frame = [self frameForUserPosition:user.meta.userPosition
									   offsetFromLifeCounter:CGPointMake(130, 80)
														size:CGSizeMake(75, 75)];
			userIconImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
			[self.userIconImageViews addObject:userIconImageView];
			[self.view addSubview:userIconImageView];
		}
		else {
			NSLog(@"could not find user icon %d", user.userIconID);
		}
		
		// create username label
		UILabel *usernameLabel = [[UILabel alloc] init];
		usernameLabel.frame = [self frameForUserPosition:user.meta.userPosition
							   offsetFromLifeCounter:CGPointMake(-200, 80)
												size:CGSizeMake(200, 30)];
		usernameLabel.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		usernameLabel.backgroundColor = [UIColor clearColor];
		usernameLabel.textAlignment = NSTextAlignmentRight;
		usernameLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME size:26];
		usernameLabel.text = user.name;
		
		[self.nameLabels addObject:usernameLabel];
		[self.view addSubview:usernameLabel];
		
		// drop some eaves
		[user addObserver:self forKeyPath:@"state.life" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
		[user addObserver:self forKeyPath:@"state.poison" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
		[user addObserver:self forKeyPath:@"state.isDead" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
	}
	
	// required below because it updates UI assembled above
	[self updatePassButtonPosition];
	
	self.isInitialized = YES;
	
	return YES;
}


#pragma mark - User Interaction

- (void)passButtonPressed {
	self.undoButton.enabled = YES;
	
	// kill anybody that needs killing
	BOOL isPromptingPlayersForDraw = ![self autoKill];
	if (isPromptingPlayersForDraw) {
		return;
	}
					
	BOOL isComplete = [self areAllUsersDead];
	if (isComplete) {
		[self matchCompleted];
	}
	else {
		[MatchManager addMatchTurnToMatch:self.match];

		[self updatePassButtonPosition];
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
														message:@"Are you sure?!\nThis will revert every player to the state at the beginning of last turn."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it!", nil];
	
	[alertView show];
}

- (void)resetTurnButtonPressed {
	self.alertReason = AlertReasonResetTurn;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will revert every player to the state at the beginning of the turn."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it!", nil];
	
	[alertView show];
}


#pragma mark - Match Helper

- (void)quitMatch {
	[MatchService deleteMatch:self.match];
	[MatchManager setActiveMatch:nil];
	
	[[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
}

// returns NO if querying players to verify a Match draw
// returns YES otherwise
- (BOOL)autoKill {
	NSUInteger numDeadUsers = 0;
	NSUInteger numUsersToKill = 0;
	for (User *user in self.match.users) {
		if (user.state.isDead) { // skip if already dead
			numDeadUsers++;
			continue;
		}
		
		if ([self shouldUserBeDead:user]) {
			numUsersToKill++;
		}
	}
	
	if (numUsersToKill > 0) {
		if (numUsersToKill + numDeadUsers >= [self.match.users count]) { // if every user will end up dead
			self.alertReason = AlertReasonVerifyMatchDraw;
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Draw?!"
																message:@"Verify that there is no single winner."
															   delegate:self
													  cancelButtonTitle:@"Cancel"
													  otherButtonTitles:@"It's a draw", nil];
			
			[alertView show];
			return NO;
		}
		else {
			for (User *user in self.match.users) {
				if (!user.state.isDead && [self shouldUserBeDead:user]) {
					user.state.isDead = YES;
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)shouldUserBeDead:(User *)user {
	return user.state.life <= 0 || user.state.poison >= self.match.poisonToDie;
}

- (BOOL)areAllUsersDead {
	NSUInteger numUsersAlive = 0;
	for (User *user in self.match.users) {
		if (!user.state.isDead) {
			numUsersAlive++;
		}
	}
	
	return numUsersAlive <= 1;
}

- (void)userDied:(User *)user {
	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserPosition:user.meta.userPosition];
	UIImageView *userIconImageView = [self userIconImageViewForUser:user];
	UILabel *nameLabel = [self nameLabelForUser:user];
	
	[UIView animateWithDuration:(self.isInitialized ? 0.40f : 0)
					 animations:^{
						 lifeCounterView.transform = CGAffineTransformScale(lifeCounterView.transform, 0.001, 0.001);
						 userIconImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(130, 200) size:userIconImageView.frame.size];
						 nameLabel.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(-200, 200) size:nameLabel.frame.size];
					 }
					 completion:^(BOOL finished) {
						 
					 }];
}
	 
- (void)userResurrected:(User *)user {
	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserPosition:user.meta.userPosition];
	UIImageView *userIconImageView = [self userIconImageViewForUser:user];
	UILabel *nameLabel = [self nameLabelForUser:user];
	
	[UIView animateWithDuration:0.40f
					 animations:^{
						 lifeCounterView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
						 userIconImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(130, 80) size:userIconImageView.frame.size];
						 nameLabel.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(-200, 80) size:nameLabel.frame.size];
					 }
					 completion:^(BOOL finished) {
						 
					 }];
}

- (void)matchCompleted {
	User *userWinner;
	for (User *user in self.match.users) {
		if (!user.state.isDead) {
			userWinner = user;
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
	
	// save current turn
	NSDate *now = [NSDate date];
	self.match.currentTurn.passTime = now;
	[MatchService updateMatchTurn:self.match.currentTurn];
	
	// save match
	self.match.winnerUserID = userWinner.ID;
	self.match.isComplete = YES;
	self.match.endTime = now;
	[MatchService updateMatch:self.match];

	if (userWinner) {
		LifeCounterView *winnerLifeCounterView = [self lifeCounterViewForUserPosition:userWinner.meta.userPosition];
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

- (void)updatePassButtonPosition {
	BOOL shouldAnimatePassButton = self.isInitialized;
	
	UserPosition userPosition = self.match.currentTurn.user.meta.userPosition;
		
	if (shouldAnimatePassButton) {
		[UIView animateWithDuration:0.20f
						 animations:^{
							 self.passButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
						 }
						 completion:^(BOOL finished) {
							 [UIView animateWithDuration:0.20f
											  animations:^{
												  self.passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:userPosition]);
											  }
											  completion:^(BOOL finished) {
												  [UIView animateWithDuration:0.20f
																   animations:^{
																	   self.passButton.frame = [self frameForUserPosition:userPosition offsetFromLifeCounter:CGPointMake(0, -136) size:self.passButton.frame.size];
																   }];
											  }];
						 }];
	}
	else {
		self.passButton.frame = [self frameForUserPosition:self.match.currentTurn.user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, -136) size:self.passButton.frame.size];
		self.passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:userPosition]);
	}
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

- (CGFloat)rotationAngleForUserPosition:(UserPosition)userPosition {
	NSAssert(userPosition > 0 && userPosition <= 4, @"UserPosition supplied is out of range (%d)", userPosition);

	switch (userPosition) {
		case UserPositionSouth:
			return 0;
			break;
		case UserPositionWest:
			return M_PI_2;
			break;
		case UserPositionNorth:
			return M_PI;
			break;
		case UserPositionEast:
			return -M_PI_2;
			break;
		default:
			return 0;
			break;
	}
}

- (CGRect)frameForUserPosition:(UserPosition)userPosition
 offsetFromLifeCounter:(CGPoint)offset
					size:(CGSize)size {
	NSAssert(userPosition > 0 && userPosition <= 4, @"UserPosition supplied is out of range (%d)", userPosition);

	LifeCounterView *lifeCounterView = [self lifeCounterViewForUserPosition:userPosition];
	
	switch (userPosition) {
		case UserPositionSouth: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 + offset.x,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 + offset.y,
							  size.width,
							  size.height);
		}	break;
		case UserPositionWest: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 - offset.y,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 + offset.x,
							  size.width,
							  size.height);
		}	break;
		case UserPositionNorth: {
			return CGRectMake(CGRectGetMidX(lifeCounterView.frame) - size.width/2 - offset.x,
							  CGRectGetMidY(lifeCounterView.frame) - size.height/2 - offset.y,
							  size.width,
							  size.height);
		}	break;
		case UserPositionEast: {
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

- (CGRect)defaultFrameForLifeCounterAtUserPosition:(UserPosition)userPosition {
	NSAssert(userPosition > 0 && userPosition <= 4, @"UserPosition supplied is out of range (%d)", userPosition);
	
	CGSize defaultSize = CGSizeMake(200, 200);
	
	switch (userPosition) {
		case UserPositionSouth: {
			return CGRectMake(CGRectGetMidX(self.view.bounds) - defaultSize.width/2,
							  CGRectGetMaxY(self.view.bounds) - defaultSize.height - 20,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserPositionWest: {
			return CGRectMake(20,
							  CGRectGetMidY(self.view.bounds) - defaultSize.height/2,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserPositionNorth: {
			return CGRectMake(CGRectGetMidX(self.view.bounds) - defaultSize.width/2,
							  20,
							  defaultSize.width,
							  defaultSize.height);
		}	break;
		case UserPositionEast: {
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

- (LifeCounterView *)lifeCounterViewForUserPosition:(UserPosition)userPosition {
	NSAssert([self.lifeCounterViews count] > 0, @"There are no name labels");

	User *user = [self.userPositionDictionary objectForKey:@(userPosition)];
	NSAssert(user, @"There is no User at slot %d", userPosition);
	
	NSUInteger userIndex = [self.match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users", userPosition);
	
	return [self.lifeCounterViews objectAtIndex:userIndex];
}

- (UIImageView *)userIconImageViewForUser:(User *)user {
	NSAssert([self.userIconImageViews count] > 0, @"There are no name labels");

	NSUInteger userIndex = [self.match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users");
	
	return [self.userIconImageViews objectAtIndex:userIndex];
}

- (UILabel *)nameLabelForUser:(User *)user {
	NSAssert([self.nameLabels count] > 0, @"There are no name labels");
	
	NSUInteger userIndex = [self.match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users");
	
	return [self.nameLabels objectAtIndex:userIndex];
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
					[MatchManager revertMatchToPreviousTurn:self.match];
					[self updatePassButtonPosition];
					self.undoButton.enabled = self.match.currentTurn.turnNumber > 1;
					break;
			}
			break;
		case AlertReasonResetTurn:
			switch (buttonIndex) {
				case 1:
					[MatchManager revertMatchToBeginningOfCurrentTurn:self.match];
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
				case 1:
					for (User *user in self.match.users) {
						if (!user.state.isDead && [self shouldUserBeDead:user]) {
							user.state.isDead = YES;
						}
					}
					
					[self matchCompleted];
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
	if ([object isKindOfClass:[User class]]) {
		User *user = (User *)object;
		
		id old = [change objectForKey:NSKeyValueChangeOldKey];
		id new = [change objectForKey:NSKeyValueChangeNewKey];
				
		if ([keyPath isEqualToString:@"state.isDead"]) {
			BOOL wasDeadBeforeChange = [old boolValue];
			BOOL isDeadNow = [new boolValue];
			
			if ((!wasDeadBeforeChange || !self.isInitialized) && isDeadNow) {
				[MatchService updateMatchTurnUserState:user.state];
				[self userDied:user];
			}
			else if (wasDeadBeforeChange && !isDeadNow) {
				[MatchService updateMatchTurnUserState:user.state];
				[self userResurrected:user];
			}
		}
		else if ([keyPath isEqualToString:@"state.life"]) {
			NSInteger oldLife = [old integerValue];
			NSInteger newLife = [new integerValue];
			
			if (oldLife != newLife) {
				[MatchService updateMatchTurnUserState:user.state];
			}
		}
		else if ([keyPath isEqualToString:@"state.poison"]) {
			NSUInteger oldPoison = [old unsignedIntegerValue];
			NSUInteger newPoison = [new unsignedIntegerValue];
			
			if (oldPoison != newPoison) {
				[MatchService updateMatchTurnUserState:user.state];
			}
		}
	}
}

@end
