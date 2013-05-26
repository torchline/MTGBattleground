//
//  UserSelectionView.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserIcon;
@class User;

@protocol UserSelectionViewDelegate;

@interface UserSelectionView : UIView

- (UserSelectionView *)initWithUser:(User *)user;

@property (nonatomic) User *user;
@property (nonatomic, weak) IBOutlet id <UserSelectionViewDelegate> delegate;

@property (nonatomic) UIButton *nameButton;
@property (nonatomic) UIButton *iconButton;
@property (nonatomic) UIButton *unsetButton;

@end


@protocol UserSelectionViewDelegate <NSObject>

@optional
- (void)userSelectionViewDidRequestNewName:(UserSelectionView *)userSelectionView;
- (void)userSelectionViewDidRequestNewIcon:(UserSelectionView *)userSelectionView;

@end