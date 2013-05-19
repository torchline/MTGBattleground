//
//  LocalUsernameListViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LocalUser;


@protocol LocalUserListViewControllerDelegate;


@interface LocalUserListViewController : UITableViewController

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id <LocalUserListViewControllerDelegate> delegate;

@end



@protocol LocalUserListViewControllerDelegate <NSObject>

@required
- (void)localUserListViewControllerDidPickUser:(LocalUser *)localUser;

@end