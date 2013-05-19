//
//  ManagableViewController.h
//  AcademicsBoard
//
//  Created by Brad Walker on 10/1/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ManagableViewPresentationStyleNone,
    
	ManagableViewPresentationStyleFadeIn,
	
    ManagableViewPresentationStyleSlideFromTop,
    ManagableViewPresentationStyleSlideFromRight,
    ManagableViewPresentationStyleSlideFromBottom,
    ManagableViewPresentationStyleSlideFromLeft,
	
	ManagableViewPresentationStylePushFromTop,
    ManagableViewPresentationStylePushFromRight,
    ManagableViewPresentationStylePushFromBottom,
    ManagableViewPresentationStylePushFromLeft
	
} ManagableViewPresentationStyle;

typedef enum {
    ManagableViewDismissionStyleNone,
    
	ManagableViewDismissionStyleFadeOut,
	
    ManagableViewDismissionStyleSlideToTop,
    ManagableViewDismissionStyleSlideToRight,
    ManagableViewDismissionStyleSlideToBottom,
    ManagableViewDismissionStyleSlideToLeft
	
} ManagableViewDismissionStyle;


@protocol ManagableViewControllerTransitionAnimationDelegate;


@interface ManagableViewController : UIViewController

@property (nonatomic) ManagableViewPresentationStyle presentationStyle;
@property (nonatomic) ManagableViewDismissionStyle dismissionStyle;
@property (nonatomic, strong) NSDictionary *viewOptions;
@property (nonatomic, unsafe_unretained) NSObject <ManagableViewControllerTransitionAnimationDelegate> *transitionAnimationDelegate;


- (void)setup;

- (void)willPresent;
- (void)willDismiss;

- (BOOL)viewDidLoadFromViewController:(ManagableViewController *)aViewController;
- (BOOL)viewWillUnloadToViewController:(ManagableViewController *)aViewController;

@end





@protocol ManagableViewControllerTransitionAnimationDelegate

@required
- (void)managableViewControllerDidFinishLoading:(ManagableViewController *)aViewController;
- (void)managableViewControllerDidFinishUnloading:(ManagableViewController *)aViewController;

@end
