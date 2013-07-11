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


@interface ManagableViewController : UIViewController {
	ManagableViewPresentationStyle _presentationStyle;
	ManagableViewDismissionStyle _dismissionStyle;
	
	NSDictionary *_viewOptions;
	
	NSObject<ManagableViewControllerTransitionAnimationDelegate> __weak *_transitionAnimationDelegate;
}

@property (nonatomic) ManagableViewPresentationStyle presentationStyle;
@property (nonatomic) ManagableViewDismissionStyle dismissionStyle;
@property (nonatomic) NSDictionary *viewOptions;
@property (nonatomic, weak) NSObject <ManagableViewControllerTransitionAnimationDelegate> *transitionAnimationDelegate;


- (void)setup;

- (void)willPresent;
- (void)willDismiss;

- (BOOL)willLoadFromViewController:(ManagableViewController *)aViewController;
- (BOOL)viewWillUnloadToViewController:(ManagableViewController *)aViewController;

@end





@protocol ManagableViewControllerTransitionAnimationDelegate

@required
- (void)managableViewControllerDidFinishLoading:(ManagableViewController *)aViewController;
- (void)managableViewControllerDidFinishUnloading:(ManagableViewController *)aViewController;

@end
