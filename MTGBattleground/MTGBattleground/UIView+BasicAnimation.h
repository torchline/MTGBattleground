//
//  UIView+BasicAnimation.h
//  AbbySentences
//
//  Created by Brad Walker on 6/1/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UIViewBasicAnimationFadeIn                @"UIViewBasicAnimationFadeIn"
#define UIViewBasicAnimationFadeOut               @"UIViewBasicAnimationFadeOut"
#define UIViewBasicAnimationFadeInOut             @"UIViewBasicAnimationFadeInOut"
#define UIViewBasicAnimationFlipFromLeftToRect    @"UIViewBasicAnimationFlipFromLeftToRect"
#define UIViewBasicAnimationFlipToCenterModalYes  @"UIViewBasicAnimationFlipToCenterModalYes"
#define UIViewBasicAnimationFlipToCenterModalNo   @"UIViewBasicAnimationFlipToCenterModalNo"


@protocol UIViewBasicAnimationDelegate;


@interface UIView (BasicAnimation)

- (void)fadeOutForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;
- (void)fadeInForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;
- (void)fadeInOut:(NSTimeInterval)duration startingAlpha:(CGFloat)startingAlpha endingAlpha:(CGFloat)endingAlpha;
- (void)hideByShrinkingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;
- (void)showByExpandingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;
- (void)showByBouncingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;

- (void)flipFromLeft:(BOOL)fromLeft toRect:(CGRect)rect duration:(NSTimeInterval)duration delegate:(NSObject <UIViewBasicAnimationDelegate> *)delegate;
- (void)flipToCenteredModal:(BOOL)toCenter duration:(NSTimeInterval)duration delegate:(NSObject <UIViewBasicAnimationDelegate> *)delegate;

@end




@protocol UIViewBasicAnimationDelegate

@required
- (void)viewFinishedAnimating:(NSString *)animationID finished:(NSNumber *)finished theView:(UIView *)theView;

@end