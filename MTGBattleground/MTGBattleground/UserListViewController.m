//
//  UserListViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserListViewController.h"
#import "User.h"
#import "UserService.h"
#import "ObjectListView.h"
#import "UserListItemView.h"
#import "UIColor+Pastel.h"


@interface UserListViewController () <ObjectListViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@end


@implementation UserListViewController


#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        _users = [UserService users];
		[_users sortUsingSelector:@selector(compareUsage:)];
		
		_badTextColor = [UIColor redPastelColor];
		_goodTextColor = [UIColor greenPastelColor];
		_frameSize = CGSizeMake(250, 340);
    }
    return self;
}

- (void)loadView {
	[super loadView];
	
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _frameSize.width, _frameSize.height)];
	self.view.backgroundColor = [UIColor offWhitePastelColor];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self setState:UserListViewControllerStateDisplay];
}

- (void)createDisplayStateView {
	_displayStateView = [UIView new];
	_displayStateView.frame = self.view.bounds;
	
	// Add Button
	_displayStateAddButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_displayStateAddButton setTitle:@"Add" forState:UIControlStateNormal];
	[_displayStateAddButton addTarget:self action:@selector(displayStateAddButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_displayStateAddButton.frame = CGRectMake(20,
											  20,
											  70,
											  40);
	[_displayStateView addSubview:_displayStateAddButton];
	
	// Edit Button
	_displayStateEditButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_displayStateEditButton setTitle:@"Edit" forState:UIControlStateNormal];
	[_displayStateEditButton addTarget:self action:@selector(displayStateEditButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_displayStateEditButton.frame = CGRectMake(self.view.bounds.size.width - 70 - 20,
											   20,
											   70,
											   40);
	[_displayStateView addSubview:_displayStateEditButton];
	
	// User List View
	_displayStateUserListView = [ObjectListView new];
	_displayStateUserListView.delegate = self;
	_displayStateUserListView.isZebraStriped = YES;
	_displayStateUserListView.zebraStripeColor = [UIColor whiteColor];
	_displayStateUserListView.backgroundColor = [UIColor offWhitePastelColor];
	CGFloat userListViewY = CGRectGetMaxY(_displayStateAddButton.frame) + _displayStateAddButton.frame.origin.y;
	_displayStateUserListView.frame = CGRectMake(0,
												 userListViewY,
												 _displayStateView.bounds.size.width,
												 _displayStateView.bounds.size.height - userListViewY);
	[_displayStateView addSubview:_displayStateUserListView];
}

- (void)createAddStateView {
	_addStateView = [UIView new];
	CGRect addViewFrame = self.view.bounds;
	addViewFrame.origin.x += self.view.bounds.size.width;
	_addStateView.frame = addViewFrame;
	
	_addStateViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addStateViewTapGestureRecognized)];
	_addStateViewTapGestureRecognizer.delegate = self;
	[_addStateView addGestureRecognizer:_addStateViewTapGestureRecognizer];
	
	// Add View Back Button
	_addStateBackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[_addStateBackButton setTitle:@"Back" forState:UIControlStateNormal];
	[_addStateBackButton addTarget:self action:@selector(addStateBackButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_addStateBackButton.frame = CGRectMake(15,
										   15,
										   70,
										   40);
	[_addStateView addSubview:_addStateBackButton];
	
	// Add View Username Text Field
	_addStateUsernameTextField = [UITextField new];
	_addStateUsernameTextField.delegate = self;
	[_addStateUsernameTextField addTarget:self action:@selector(addStateUsernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
	_addStateUsernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	_addStateUsernameTextField.font = [UIFont fontWithName:GLOBAL_FONT_NAME size:36];
	_addStateUsernameTextField.borderStyle = UITextBorderStyleRoundedRect;
	_addStateUsernameTextField.frame = CGRectMake(_addStateBackButton.frame.origin.x,
												  CGRectGetMaxY(_addStateBackButton.frame) + _addStateBackButton.frame.origin.y,
												  _addStateView.bounds.size.width - _addStateBackButton.frame.origin.x * 2,
												  48);
	[_addStateView addSubview:_addStateUsernameTextField];
	
	// Add View Complete Button
	_addStateCompleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	_addStateCompleteButton.enabled = NO;
	[_addStateCompleteButton setTitle:@"Save" forState:UIControlStateNormal];
	[_addStateCompleteButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
	[_addStateCompleteButton addTarget:self action:@selector(addStateCompleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	_addStateCompleteButton.frame = CGRectMake(_addStateBackButton.frame.origin.x,
											   CGRectGetMaxY(_addStateUsernameTextField.frame) + _addStateBackButton.frame.origin.y,
											   _addStateView.bounds.size.width - _addStateBackButton.frame.origin.x * 2,
											   40);
	[_addStateView addSubview:_addStateCompleteButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self refreshDisplayedUsers];
}


#pragma mark - System

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated]; 
	
	[_displayStateUserListView selectObject:nil animated:NO scrollPosition:ObjectListViewScrollPositionNone];
	
	self.state = UserListViewControllerStateDisplay;
}


#pragma mark - User Interaction

- (void)displayStateAddButtonPressed {
	[self setState:UserListViewControllerStateAdd animated:YES completion:nil];
}

- (void)displayStateEditButtonPressed {
	if (_displayStateUserListView.isEditing) {
		[_displayStateUserListView exitEditingModeAnimated:YES];
	}
	else {
		[_displayStateUserListView enterEditingModeAnimated:YES];
	}
}

- (void)addStateBackButtonPressed {
	_addStateUsernameTextField.text = nil;
	
	[self setState:UserListViewControllerStateDisplay animated:YES completion:nil];
}

- (void)addStateUsernameTextFieldChanged {
	NSString *proposedUsername = [_addStateUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([proposedUsername length] > 0) {
		BOOL usernameExists = [UserService doesUsernameExist:proposedUsername];
		
		_addStateUsernameTextField.textColor = usernameExists ? _badTextColor : _goodTextColor;
		_addStateCompleteButton.enabled = !usernameExists;
	}
	else {
		_addStateCompleteButton.enabled = NO;
	}
}

- (void)addStateViewTapGestureRecognized {
	[_addStateView endEditing:YES];
}

- (void)addStateCompleteButtonPressed {
	User *newUser = [[User alloc] initWithID:[Service newGUID]
										name:_addStateUsernameTextField.text
								  userIconID:0
								numTimesUsed:0
								lastTimeUsed:nil];
	
	[UserService createUser:newUser];
	
	
	[self refreshUserList];
	
	UIButton __block *addStateCompleteButton = _addStateCompleteButton;
	[self setState:UserListViewControllerStateDisplay animated:YES completion:^{
		addStateCompleteButton.enabled = NO;
	}];
	
	_addStateUsernameTextField.text = nil;
}


#pragma mark - Helper

- (void)refreshUserList {
	_users = [UserService users];
	[_users sortUsingSelector:@selector(compareUsage:)];
	
	[self refreshDisplayedUsers];
}

- (void)refreshDisplayedUsers {
	// Use the delegate method to determine any names we don't want to display
	_displayedUsers = nil;
	if ([_delegate respondsToSelector:@selector(userListViewControllerDisallowedUsers:)]) {
		NSArray *disallowedUsers = [_delegate userListViewControllerDisallowedUsers:self];
		
		if (disallowedUsers) {
			NSMutableArray *usersCopy = [_users mutableCopy];
			[usersCopy removeObjectsInArray:disallowedUsers];
			_displayedUsers = usersCopy;
		}
	}
	if (!_displayedUsers) {
		_displayedUsers = _users;
	}
	
	[_displayStateUserListView setObjects:_displayedUsers objectViewClass:[UserListItemView class] gap:0];	
}


#pragma mark - Delegate

- (void)objectListView:(ObjectListView *)objectListView didSelectObject:(id)object {
	if ([objectListView isEqual:_displayStateUserListView]) {
		User *user = (User *)object;
		
		[_delegate userListViewController:self didPickUser:user];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	BOOL shouldReturn = YES;
	
	if ([textField isEqual:_addStateUsernameTextField]) {
		[_addStateView endEditing:YES];
	}
	
	return shouldReturn;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	return [touch.view isEqual:_addStateView];
}



#pragma mark - Getter / Setter

- (void)setState:(UserListViewControllerState)state {
	[self setState:state animated:NO completion:nil];
}

- (void)setState:(UserListViewControllerState)state animated:(BOOL)animated completion:(void (^)(void))completion {
	if (state == _state) {
		return;
	}
	
	_state = state;
	
	UIView *oldStateView = _currentStateView;
	
	CGRect viewBounds;
	switch (state) {
		case UserListViewControllerStateDisplay:
			if (!_displayStateView) {
				[self createDisplayStateView];
			}
			
			_displayStateUserListView.contentOffset = CGPointZero;
			
			_currentStateView = _displayStateView;
			
			viewBounds = CGRectMake(0,
									0,
									_frameSize.width,
									_frameSize.height);
			break;
		case UserListViewControllerStateAdd:
			if (!_addStateView) {
				[self createAddStateView];
			}
			
			_currentStateView = _addStateView;
			
			viewBounds = CGRectMake(_frameSize.width,
									0,
									_frameSize.width,
									_frameSize.height);
			break;
			
		default:
			_currentStateView = nil;
			break;
	}
	
	[self.view addSubview:_currentStateView];
	
	[UIView animateWithDuration:animated ? 0.30f : 0
					 animations:^{
						 self.view.bounds = viewBounds;
					 }
					 completion:^(BOOL finished) {
						 [oldStateView removeFromSuperview];
						 
						 if (completion) {
							 completion();
						 }
					 }];
}



@end
