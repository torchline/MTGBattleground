//
//  UserIconListViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UserIconListViewDelegate;
@class UserIcon;

@interface UserIconListViewController : UIViewController

@property (nonatomic, weak) IBOutlet id <UserIconListViewDelegate> delegate;

@end



@protocol UserIconListViewDelegate <NSObject>

@optional
- (void)userIconListViewControllerDidPickUserIcon:(UserIcon *)userIcon;

@end