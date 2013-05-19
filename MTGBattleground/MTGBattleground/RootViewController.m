//
//  RootViewController.m
//  AcademicsBoard
//
//  Created by Brad Walker on 9/12/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController

#pragma mark - System

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
