//
//  UsernameListViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum : NSUInteger {
	UserListViewControllerStateDisplay = 1,
	UserListViewControllerStateAdd
} UserListViewControllerState;


@protocol UserListViewControllerDelegate;

@class User;
@class ObjectListView;


@interface UserListViewController : UIViewController {
	CGSize _frameSize;
	
	UIView __weak *_currentStateView;
	
	
	// Display View
	NSMutableArray *_users;
	NSArray *_displayedUsers;
	
	UIView *_displayStateView;
	ObjectListView *_displayStateUserListView;
	UIButton *_displayStateAddButton;
	UIButton *_displayStateEditButton;
	
	
	// Add View
	UIColor *_badTextColor;
	UIColor *_goodTextColor;
	UITapGestureRecognizer *_addStateViewTapGestureRecognizer;
	
	UIView *_addStateView;
	UIButton *_addStateBackButton;
	UIButton *_addStateCompleteButton;
	UITextField *_addStateUsernameTextField;
}

@property (nonatomic, weak) IBOutlet id <UserListViewControllerDelegate> delegate;
@property (nonatomic) UserListViewControllerState state;

- (void)setState:(UserListViewControllerState)state animated:(BOOL)animated completion:(void (^)(void))completion;

@end



@protocol UserListViewControllerDelegate <NSObject>

@required
- (void)userListViewController:(UserListViewController *)controller didPickUser:(User *)user;

@optional
- (NSArray *)userListViewControllerDisallowedUsers:(UserListViewController *)controller;

@end