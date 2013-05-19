//
//  LocalUsernameListViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "LocalUserListViewController.h"
#import "Database.h"
#import "LocalUser.h"

@interface LocalUserListViewController ()

@property (nonatomic) NSMutableArray *localUserNames;

@end


@implementation LocalUserListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.localUserNames = [Database localUsers];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


#pragma mark - Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.localUserNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
    cell.textLabel.text = [(LocalUser *)[self.localUserNames objectAtIndex:indexPath.row] name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.delegate respondsToSelector:@selector(localUserListViewControllerDidPickUser:)]) {
		[self.delegate localUserListViewControllerDidPickUser:[self.localUserNames objectAtIndex:indexPath.row]];
	}
}


@end
