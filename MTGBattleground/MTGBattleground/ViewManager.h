//
//  ViewManager.h
//  AcademicsBoard
//
//  Created by Brad Walker on 9/10/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "ManagableViewController.h"

#define ViewOptionWasResurrected		@"ViewOptionWasResurrected"


@class AccessoryViewController;


@interface ViewManager : NSObject <ManagableViewControllerTransitionAnimationDelegate> {
	BOOL isAnimatingAccessoryView;
	Class lastViewControllerClass, nextAccessoryViewControllerClass;
		
    NSMutableArray *previousViewControllerClasses;
	NSMutableDictionary *accessoryViewControllerCache;

	ManagableViewController *currentViewController, *nextViewController, *lastViewController;
    AccessoryViewController *__unsafe_unretained currentAccessoryViewController;
    
    UIButton *overlayButton;
    UIView *rootView;
}

@property (unsafe_unretained, nonatomic, readonly) Class previousViewControllerClass;
@property (nonatomic, strong, readonly) ManagableViewController *currentViewController;
@property (unsafe_unretained, nonatomic, readonly) AccessoryViewController *currentAccessoryViewController;

+ (ViewManager *)sharedInstance;
- (id)initWithRootView:(UIView *)rootView;

- (void)switchToView:(Class)viewControllerClass;
- (void)switchToView:(Class)viewControllerClass options:(NSDictionary *)options;
- (void)switchToPreviousView;
- (void)switchToPreviousViewWithOptions:(NSDictionary *)options;

- (void)openAccessoryViewWithClass:(Class)aClass;
- (void)closeAccessoryView;

@end
