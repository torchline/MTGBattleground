//
//  LocalUserSelectionView.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserIcon;
@class LocalUser;

@protocol LocalUserSelectionViewDelegate;

@interface LocalUserSelectionView : UIView

- (LocalUserSelectionView *)initWithLocalUser:(LocalUser *)localUser;

@property (nonatomic) LocalUser *localUser;
@property (nonatomic, weak) IBOutlet id <LocalUserSelectionViewDelegate> delegate;

@property (nonatomic) UIButton *nameButton;
@property (nonatomic) UIButton *iconButton;
@property (nonatomic) UIButton *unsetButton;

@end


@protocol LocalUserSelectionViewDelegate <NSObject>

@optional
- (void)localUserSelectionViewDidRequestNewName:(LocalUserSelectionView *)localUserSelectionView;
- (void)localUserSelectionViewDidRequestNewIcon:(LocalUserSelectionView *)localUserSelectionView;

@end