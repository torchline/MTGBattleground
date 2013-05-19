//
//  UserIconView.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserIcon;
@protocol UserIconViewDelegate;

@interface UserIconView : UIView

- (UserIconView *)initWithUserIcon:(UserIcon *)userIcon;

@property (nonatomic) UIButton *button;
@property (nonatomic) UserIcon *userIcon;
@property (nonatomic, weak) IBOutlet id <UserIconViewDelegate> delegate;

@end




@protocol UserIconViewDelegate <NSObject>

- (void)userIconViewPressed:(UserIconView *)userIconView;

@end