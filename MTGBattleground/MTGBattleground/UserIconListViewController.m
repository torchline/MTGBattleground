//
//  UserIconListViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserIconListViewController.h"
#import "KJGridLayout.h"
#import "Database.h"
#import "UserIcon.h"
#import "UserIconView.h"

@interface UserIconListViewController () <UserIconViewDelegate>

@property (nonatomic) KJGridLayout *gridLayoutManager;
@property (nonatomic) NSMutableArray *userIcons;

@end


@implementation UserIconListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.gridLayoutManager = [KJGridLayout new];
	self.userIcons = [Database userIcons];
	
	NSUInteger i = 0;
	for (UserIcon *userIcon in self.userIcons) {
		NSUInteger rowIndex = i / 3;
        NSUInteger columnIndex = i % 3;
		
		UserIconView *userIconView = [[UserIconView alloc] initWithUserIcon:userIcon];
		userIconView.frame = CGRectMake(0, 0, 100, 100);
		userIconView.delegate = self;
		
		[self.view addSubview:userIconView];
		[self.gridLayoutManager addView:userIconView row:rowIndex column:columnIndex];
		
		[self.gridLayoutManager setBounds:[self.view bounds]];		
		[self.gridLayoutManager layoutViews];
		
		i++;
	}
}


#pragma mark - Delegate

- (void)userIconViewPressed:(UserIconView *)userIconView {
	if ([self.delegate respondsToSelector:@selector(userIconListViewControllerDidPickUserIcon:)]) {
		[self.delegate userIconListViewControllerDidPickUserIcon:userIconView.userIcon];
	}
}

@end
