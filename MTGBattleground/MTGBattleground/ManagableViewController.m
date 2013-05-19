//
//  ManagableViewController.m
//  AcademicsBoard
//
//  Created by Brad Walker on 10/1/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import "ManagableViewController.h"

@interface ManagableViewController ()

@end


@implementation ManagableViewController


#pragma mark - System

- (void)dealloc {
	self.transitionAnimationDelegate = nil;
}


#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
		[self setup];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self setup];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup {
	self.presentationStyle = ManagableViewPresentationStyleNone;
	self.dismissionStyle = ManagableViewDismissionStyleNone;	
}


#pragma mark - Public

- (void)willPresent {}
- (void)willDismiss {}

- (BOOL)viewDidLoadFromViewController:(ManagableViewController *)aViewController {
    return YES;
}

- (BOOL)viewWillUnloadToViewController:(ManagableViewController *)aViewController {
    return YES;
}


@end
