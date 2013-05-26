//
//  UsernameListViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;


@protocol UserListViewControllerDelegate;


@interface UserListViewController : UIViewController

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id <UserListViewControllerDelegate> delegate;

@end



@protocol UserListViewControllerDelegate <NSObject>

@required
- (void)userListViewControllerDidPickUser:(User *)user;

@end