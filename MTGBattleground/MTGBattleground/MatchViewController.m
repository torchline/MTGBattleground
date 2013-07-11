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
#import "FireLayer.h"
#import "DynamicCounterView.h"

#import "User+Runtime.h"
#import "Match+Runtime.h"
#import "MatchTurn+Runtime.h"
#import "UserIcon.h"


static inline CGFloat pointDistance(CGPoint point1, CGPoint point2) {
	return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2));
}


@interface MatchViewController () <DynamicCounterViewDelegate>

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
	for (User *user in _match.users) {
		[user removeObserver:self forKeyPath:@"state.poison"];
		[user removeObserver:self forKeyPath:@"state.life"];
		[user removeObserver:self forKeyPath:@"state.isDead"];
	}
}


#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_presentationStyle = ManagableViewPresentationStylePushFromRight;
		
		_alertReason = -1;
		_isInitialized = NO;
		
		_lifeCounterViews = [[NSMutableArray alloc] initWithCapacity:4];
		_nameLabels = [[NSMutableArray alloc] initWithCapacity:4];
		_userIconImageViews = [[NSMutableArray alloc] initWithCapacity:4];
		_glow1ImageViews = [[NSMutableArray alloc] initWithCapacity:4];
		_glow2ImageViews = [[NSMutableArray alloc] initWithCapacity:4];
		_dynamicCounterViews = [[NSMutableSet alloc] initWithCapacity:5];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// System
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	// Match
	_match = [self.viewOptions objectForKey:VIEW_OPTION_MATCH];
	[MatchManager prepareMatchForPlaying:_match];
	
	NSAssert(_match, @"No Match passed");
	NSAssert(_match.users, @"Match has no Users");
	
	if (!_match.startTime) {
		_match.startTime = [NSDate date];
		[MatchService updateMatch:_match];
	}
	
	if (_match.currentTurn.turnNumber == 1) {
		_undoButton.enabled = NO;
	}
	
	// add tap-hold gesture recognizer to detect dynamic counter creation
	if (_match.enableDynamicCounters) {
		_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized)];
		_longPressGestureRecognizer.delegate = self;
		[self.view addGestureRecognizer:_longPressGestureRecognizer];
	}

	// Pass Button
	if (_match.enableTurnTracking) {
		UIImage *passButtonImage = [UIImage imageNamed:@"PassButton.png"];
		_passButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_passButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 60, 0);
		[_passButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		_passButton.adjustsImageWhenHighlighted = NO;
		_passButton.titleLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME_BOLD size:40];
		[_passButton setTitle:@"Pass" forState:UIControlStateNormal];
		[_passButton setBackgroundImage:passButtonImage forState:UIControlStateNormal];
		[_passButton addTarget:self action:@selector(passButtonPressed) forControlEvents:UIControlEventTouchDown];
		_passButton.frame = CGRectMake(0, 0, passButtonImage.size.width, passButtonImage.size.height);
		[self.view addSubview:_passButton];
	}
	
	// Quit Button
	_quitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_quitButton setTitle:@"Quit" forState:UIControlStateNormal];
	[_quitButton addTarget:self action:@selector(quitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_quitButton.frame = CGRectMake(20, 20, 60, 60);
	[self.view addSubview:_quitButton];
	
	// Undo Button
	_undoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_undoButton setTitle:@"Back" forState:UIControlStateNormal];
	[_undoButton addTarget:self action:@selector(undoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_undoButton.frame = CGRectMake(CGRectGetMaxX(self.view.bounds) - 60 - 20, CGRectGetMaxY(self.view.bounds) - 60 - 20, 60, 60);
	[self.view addSubview:_undoButton];
	
	// Reset Turn Button
	_resetTurnButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_resetTurnButton setTitle:@"Reset" forState:UIControlStateNormal];
	[_resetTurnButton addTarget:self action:@selector(resetTurnButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_resetTurnButton.frame = CGRectOffset(_undoButton.frame, 0, -80);
	[self.view addSubview:_resetTurnButton];
	
	NSMutableDictionary *userIconDictionary = [UserService userIconDictionary];
	
	UIImage *glow1Image = [UIImage imageNamed:@"RayGlow1.png"];
	UIImage *glow2Image = [UIImage imageNamed:@"RayGlow2.png"];
	
	_userPositionDictionary = [[NSMutableDictionary alloc] initWithCapacity:[_match.users count]];
	
	// User Controls
	for (User *user in _match.users) {
		NSAssert(user.meta, @"User has no meta");
		NSAssert(user.meta.userPosition > 0 && user.meta.userPosition <= 4, @"UserPosition %d for '%@' is invalid", user.meta.userPosition, user.name);

		// organize Users for faster access
		[_userPositionDictionary setObject:user forKey:@(user.meta.userPosition)];
		
		// Life Counter
		LifeCounterView *lifeCounterView = [[LifeCounterView alloc] initWithFrame:[self defaultFrameForLifeCounterAtUserPosition:user.meta.userPosition]];
		lifeCounterView.user = user;
		lifeCounterView.transform = CGAffineTransformRotate(lifeCounterView.transform, [self rotationAngleForUserPosition:user.meta.userPosition]);
		[_lifeCounterViews addObject:lifeCounterView];
		[self.view addSubview:lifeCounterView];
		
		// Glow Images
		UIImage *coloredGlow1Image = [self recolorImage:glow1Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow1ImageView = [[UIImageView alloc] initWithImage:coloredGlow1Image];
		glow1ImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, 60) size:glow1ImageView.frame.size];
		glow1ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		glow1ImageView.alpha = 0.60f;
		[_glow1ImageViews addObject:glow1ImageView];
		[self.view insertSubview:glow1ImageView belowSubview:lifeCounterView];

		UIImage *coloredGlow2Image = [self recolorImage:glow2Image color:[UIColor colorWithRed:(arc4random() % 100) / 100. green:(arc4random() % 100) / 100. blue:(arc4random() % 100) / 100. alpha:1]];
		UIImageView *glow2ImageView = [[UIImageView alloc] initWithImage:coloredGlow2Image];
		glow2ImageView.frame = [self frameForUserPosition:user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, 60) size:glow2ImageView.frame.size];
		glow2ImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		glow2ImageView.alpha = 0.60f;
		[_glow2ImageViews addObject:glow2ImageView];
		[self.view insertSubview:glow2ImageView belowSubview:lifeCounterView];
		
		// User Icon
		UserIcon *userIcon = user.icon ? user.icon : [userIconDictionary objectForKey:@(user.userIconID)];
		if (userIcon) {
			UIImageView *userIconImageView = [[UIImageView alloc] initWithImage:userIcon.image];
			userIconImageView.frame = [self frameForUserPosition:user.meta.userPosition
									   offsetFromLifeCounter:CGPointMake(130, 80)
														size:CGSizeMake(75, 75)];
			userIconImageView.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
			[_userIconImageViews addObject:userIconImageView];
			[self.view addSubview:userIconImageView];
		}
		else {
			NSLog(@"could not find user icon %d", user.userIconID);
		}
		
		// Username label
		UILabel *usernameLabel = [UILabel new];
		usernameLabel.frame = [self frameForUserPosition:user.meta.userPosition
							   offsetFromLifeCounter:CGPointMake(-200, 80)
												size:CGSizeMake(200, 30)];
		usernameLabel.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:user.meta.userPosition]);
		usernameLabel.backgroundColor = [UIColor clearColor];
		usernameLabel.textAlignment = NSTextAlignmentRight;
		usernameLabel.font = [UIFont fontWithName:GLOBAL_FONT_NAME size:26];
		usernameLabel.text = user.name;
		
		[_nameLabels addObject:usernameLabel];
		[self.view addSubview:usernameLabel];
		
		// Key Value Observing
		[user addObserver:self forKeyPath:@"state.life" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
		[user addObserver:self forKeyPath:@"state.poison" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
		[user addObserver:self forKeyPath:@"state.isDead" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
	}
	
	// required below because it updates UI assembled above
	[self updatePassButtonPosition];
	
	_isInitialized = YES;
}


#pragma mark - User Interaction

- (void)passButtonPressed {
	_undoButton.enabled = YES;
	
	for (LifeCounterView *lifeCounterView in _lifeCounterViews) {
		[lifeCounterView commitLifeChange];
	}
	
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
		[MatchManager completeCurrentTurnForMatch:_match];

		[self updatePassButtonPosition];
	}
}

- (void)quitButtonPressed {
	_alertReason = AlertReasonQuit;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will destroy all traces of this match."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it to it!", nil];
	
	[alertView show];
}

- (void)undoButtonPressed {
	_alertReason = AlertReasonUndo;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will revert every player to the state at the beginning of last turn."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it!", nil];
	
	[alertView show];
}

- (void)resetTurnButtonPressed {
	_alertReason = AlertReasonResetTurn;
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning!"
														message:@"Are you sure?!\nThis will revert every player to the state at the beginning of the turn."
													   delegate:self
											  cancelButtonTitle:@"Cancel"
											  otherButtonTitles:@"Do it!", nil];
	
	[alertView show];
}

- (void)longPressGestureRecognized {
	switch (_longPressGestureRecognizer.state) {
		case UIGestureRecognizerStateBegan: {
			[self addDynamicCounterViewAtPoint:[_longPressGestureRecognizer locationInView:self.view]];
		}	break;
			
		default:
			break;
	}
}


#pragma mark - Match Helper

- (void)quitMatch {
	[MatchManager setActiveMatch:nil];
	
	[[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
}

- (void)quitAndDeleteMatch {
	[MatchService deleteMatch:_match];
	[self quitMatch];
}

// returns NO if querying players to verify a Match draw
// returns YES otherwise
- (BOOL)autoKill {
	NSUInteger numDeadUsers = 0;
	NSUInteger numUsersToKill = 0;
	for (User *user in _match.users) {
		if (user.state.isDead) { // skip if already dead
			numDeadUsers++;
			continue;
		}
		
		if ([self shouldUserBeDead:user]) {
			numUsersToKill++;
		}
	}
	
	if (numUsersToKill > 0) {
		if (numUsersToKill + numDeadUsers >= [_match.users count]) { // if every user will end up dead
			_alertReason = AlertReasonVerifyMatchDraw;
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Draw?!"
																message:@"Verify that there is no single winner."
															   delegate:self
													  cancelButtonTitle:@"Cancel"
													  otherButtonTitles:@"It's a draw", nil];
			
			[alertView show];
			return NO;
		}
		else {
			for (User *user in _match.users) {
				if (!user.state.isDead && [self shouldUserBeDead:user]) {
					user.state.isDead = YES;
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)shouldUserBeDead:(User *)user {
	return user.state.life <= 0 || user.state.poison >= _match.poisonToDie;
}

- (BOOL)areAllUsersDead {
	NSUInteger numUsersAlive = 0;
	for (User *user in _match.users) {
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
	
	[UIView animateWithDuration:(_isInitialized ? 0.40f : 0)
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
	for (User *user in _match.users) {
		if (!user.state.isDead) {
			userWinner = user;
			break;
		}
	}
			
	[UIView animateWithDuration:0.40f
					 animations:^{
						 _passButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
					 }
					 completion:^(BOOL finished) {
						 [UIView animateWithDuration:0.40f
										  animations:^{
											  _passButton.transform = CGAffineTransformScale(_passButton.transform, 0.001, 0.001);
										  }
										  completion:^(BOOL finished) {
											  
										  }];
					 }];
	
	[self disableInterfaceForAnimation:YES];
	
	// save current turn
	NSDate *now = [NSDate date];
	_match.currentTurn.passTime = now;
	[MatchService updateMatchTurn:_match.currentTurn];
	
	// save match
	_match.winnerUserID = userWinner.ID;
	_match.isComplete = YES;
	_match.endTime = now;
	[MatchService updateMatch:_match];

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
								 [self quitMatch];
							 });
						 }];
	}
	else {
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self quitMatch];
		});
	}
}


#pragma mark - Helper

- (void)updatePassButtonPosition {
	BOOL shouldAnimatePassButton = _isInitialized;
	
	UserPosition userPosition = _match.currentTurn.user.meta.userPosition;
		
	if (shouldAnimatePassButton) {
		[UIView animateWithDuration:0.20f
						 animations:^{
							 _passButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
						 }
						 completion:^(BOOL finished) {
							 [UIView animateWithDuration:0.20f
											  animations:^{
												  _passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:userPosition]);
											  }
											  completion:^(BOOL finished) {
												  [UIView animateWithDuration:0.20f
																   animations:^{
																	   _passButton.frame = [self frameForUserPosition:userPosition offsetFromLifeCounter:CGPointMake(0, -136) size:_passButton.frame.size];
																   }];
											  }];
						 }];
	}
	else {
		_passButton.frame = [self frameForUserPosition:_match.currentTurn.user.meta.userPosition offsetFromLifeCounter:CGPointMake(0, -136) size:_passButton.frame.size];
		_passButton.transform = CGAffineTransformMakeRotation([self rotationAngleForUserPosition:userPosition]);
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
	
	CGImageRef coloredCGImage = CGBitmapContextCreateImage(context);
	
	CGContextRelease(context);
	
	UIImage *coloredImage = [UIImage imageWithCGImage:coloredCGImage];
	
	CGImageRelease(coloredCGImage);
	
	return coloredImage;
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
	NSAssert([_lifeCounterViews count] > 0, @"There are no name labels");

	User *user = [_userPositionDictionary objectForKey:@(userPosition)];
	NSAssert(user, @"There is no User at slot %d", userPosition);
	
	NSUInteger userIndex = [_match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users", userPosition);
	
	return [_lifeCounterViews objectAtIndex:userIndex];
}

- (UIImageView *)userIconImageViewForUser:(User *)user {
	NSAssert([_userIconImageViews count] > 0, @"There are no name labels");

	NSUInteger userIndex = [_match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users");
	
	return [_userIconImageViews objectAtIndex:userIndex];
}

- (UILabel *)nameLabelForUser:(User *)user {
	NSAssert([_nameLabels count] > 0, @"There are no name labels");
	
	NSUInteger userIndex = [_match.users indexOfObject:user];
	NSAssert(user, @"That user is not one of the current users");
	
	return [_nameLabels objectAtIndex:userIndex];
}

- (void)disableInterfaceForAnimation:(BOOL)disable {
	self.view.userInteractionEnabled = !disable;
}

- (void)addDynamicCounterViewAtPoint:(CGPoint)point {
	CGFloat size = 60;
	
	NSUInteger closestLifeCounterIndex = -1;;
	CGFloat closestDistance = INFINITY;
	NSUInteger i = 0;
	for (LifeCounterView *lifeCounterView in _lifeCounterViews) {
		CGFloat distance = pointDistance(point, lifeCounterView.center);
		
		if (distance < closestDistance) {
			closestLifeCounterIndex = i;
			closestDistance = distance;
		}
		
		i++;
	}
	
	NSAssert(closestLifeCounterIndex >= 0, @"Closest Life Counter View not found");
	
	User *user = [_match.users objectAtIndex:closestLifeCounterIndex];
	CGFloat rotation = [self rotationAngleForUserPosition:user.meta.userPosition];
	
	DynamicCounterView *dynamicCounterView = [[DynamicCounterView alloc] initWithFrame:CGRectMake(point.x - size/2, point.y - size/2, size, size)];
	dynamicCounterView.delegate = self;
	dynamicCounterView.transform = CGAffineTransformMakeRotation(rotation);
	[self.view addSubview:dynamicCounterView];

	[_dynamicCounterViews addObject:dynamicCounterView];
}


#pragma mark - Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch (_alertReason) {
		case AlertReasonUndo:
			switch (buttonIndex) {
				case 1:
					[MatchManager revertMatchToPreviousTurn:_match];
					[self updatePassButtonPosition];
					_undoButton.enabled = _match.currentTurn.turnNumber > 1;
					break;
			}
			break;
		case AlertReasonResetTurn:
			switch (buttonIndex) {
				case 1:
					[MatchManager revertMatchToBeginningOfCurrentTurn:_match];
					break;
			}
			break;
		case AlertReasonQuit:
			switch (buttonIndex) {
				case 1:
					[self quitAndDeleteMatch];
					break;
			}
			break;
		case AlertReasonVerifyMatchDraw:
			switch (buttonIndex) {
				case 1:
					for (User *user in _match.users) {
						if (!user.state.isDead && [self shouldUserBeDead:user]) {
							user.state.isDead = YES;
						}
					}
					
					[self matchCompleted];
					break;
			}
			break;
			
		default:
			NSAssert(NO, @"AlertReason is invalid: %d", _alertReason);
			break;
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	return [touch.view isEqual:self.view];
}

- (void)dynamicCounterViewDidRequestToBeDeleted:(DynamicCounterView *)dynamicCounterView {
	[dynamicCounterView removeFromSuperview];
	[_dynamicCounterViews removeObject:dynamicCounterView];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([object isKindOfClass:[User class]]) {
		User *user = (User *)object;
		
		id old = [change objectForKey:NSKeyValueChangeOldKey];
		id new = [change objectForKey:NSKeyValueChangeNewKey];
		NSAssert(![old isKindOfClass:[NSNull class]] && ![new isKindOfClass:[NSNull class]], @"Old or New is an NSNull, old: %@, new: %@", old, new);
		
		if ([keyPath isEqualToString:@"state.isDead"]) {
			BOOL wasDeadBeforeChange = [old boolValue];
			BOOL isDeadNow = [new boolValue];
			
			if ((!wasDeadBeforeChange || !_isInitialized) && isDeadNow) {
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
