//
//  UIView+BasicAnimation.m
//  AbbySentences
//
//  Created by Brad Walker on 6/1/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import "UIView+BasicAnimation.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@interface UIView (Private)
- (void)flipToCenteredModalDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)backgroundViewPressed;
@end


@implementation UIView (BasicAnimation)

static char backgroundViewKey, oldIndexKey, oldFrameKey, lastUsedDurationKey, lastUsedDelegateKey;

- (void)fadeOutForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	if (self.hidden || self.alpha == 0) {
		if (completion) {
			completion(NO);
		}
		
		self.hidden = YES;
		
		return;
	}
	
	CGFloat oldAlpha = self.alpha;
	
	[UIView animateWithDuration:duration
					 animations:^{
						 self.alpha = 0;
					 }
					 completion:^(BOOL finished) {
						 self.hidden = YES;
						 self.alpha = oldAlpha;
						 
						 if (completion) {
							 completion(finished);
						 }
					 }];
}


- (void)fadeInForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	if (self.alpha == 1) {
		if (completion) {
			completion(NO);
		}
		
		self.hidden = NO;
		
		return;
	}
	
	CGFloat oldAlpha = self.alpha;
	
	if (self.hidden) {
		self.alpha = 0;
		self.hidden = NO;
	}
		
	[UIView animateWithDuration:duration
					 animations:^{
						 self.alpha = oldAlpha;
					 }
					 completion:^(BOOL finished) {
						 if (completion) {
							 completion(finished);
						 }
					 }];
}


- (void)fadeInOut:(NSTimeInterval)duration startingAlpha:(CGFloat)startingAlpha endingAlpha:(CGFloat)endingAlpha {
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionRepeat
					 animations:^{
						 self.alpha = startingAlpha;
					 }
					 completion:^(BOOL finished) {
						 [UIView animateWithDuration:duration
										  animations:^{
											  self.alpha = endingAlpha;
										  }];
					 }];
}

- (void)hideByShrinkingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	if (self.hidden) {
		if (completion) {
			completion(NO);
		}
		return;
	}
	
	[UIView animateWithDuration:duration
					 animations:^{
						 self.transform = CGAffineTransformScale(self.transform, 0.001f, 0.001f);
					 } completion:^(BOOL finished) {
						 self.hidden = YES;
						 self.transform = CGAffineTransformScale(self.transform, 1, 1);
						 
						 if (completion) {
							 completion(finished);
						 }
					 }];
}

- (void)showByExpandingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	if (!self.hidden) {
		if (completion) {
			completion(NO);
		}
		return;
	}
	
	self.transform = CGAffineTransformScale(self.transform, 0.001f, 0.001f);
	self.hidden = NO;
	
	[UIView animateWithDuration:duration
					 animations:^{
						 self.transform = CGAffineTransformScale(self.transform, 1, 1);
					 }
					 completion:^(BOOL finished) {
						 if (completion) {
							 completion(finished);
						 }
					 }];
}

- (void)showByBouncingForDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion {
	if (!self.hidden) {
		if (completion) {
			completion(NO);
		}
		return;
	}
	
	CGAffineTransform startingTransform = self.transform;
	
	self.transform = CGAffineTransformScale(self.transform, 0.001f, 0.001f);
	self.hidden = NO;
	
	NSTimeInterval durationScale = duration / (0.15f + 0.08f + 0.10f);
	
	[UIView animateWithDuration:(0.15f * durationScale) animations:^{
		self.transform = CGAffineTransformScale(self.transform, 1.07f, 1.07f);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:(0.08f * durationScale) animations:^{
			self.transform = CGAffineTransformScale(self.transform, 0.95f, 0.95f);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:(0.10f * durationScale) animations:^{
				self.transform = CGAffineTransformScale(startingTransform, 1000, 1000);
			} completion:^(BOOL finished) {
				if (completion) {
					completion(finished);
				}
			}];
		}];
	}];
}

- (void)flipFromLeft:(BOOL)fromLeft toRect:(CGRect)rect duration:(NSTimeInterval)duration delegate:(NSObject <UIViewBasicAnimationDelegate> *)delegate {
    [UIView beginAnimations:UIViewBasicAnimationFlipFromLeftToRect context:(__bridge void *)(self)];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
    [UIView setAnimationTransition:fromLeft ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight
                           forView:self
                             cache:YES];
	if (delegate != nil) {
		[UIView setAnimationDelegate:delegate];
		[UIView setAnimationDidStopSelector:@selector(viewFinishedAnimating:finished:theView:)];
	}
	
	self.frame = rect;
	
	[UIView commitAnimations];
}

- (void)flipToCenteredModal:(BOOL)toCenter duration:(NSTimeInterval)duration delegate:(NSObject <UIViewBasicAnimationDelegate> *)delegate {
    UIView *backgroundView = (UIView *)objc_getAssociatedObject(self, &backgroundViewKey);
    objc_setAssociatedObject(self, &lastUsedDurationKey, [NSNumber numberWithFloat:duration], OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, &lastUsedDelegateKey, delegate, OBJC_ASSOCIATION_ASSIGN);

	if (toCenter) {
        if (backgroundView == nil) {
            // create dynamic background view
            UIButton *tmpBackgroundView = [UIButton buttonWithType:UIButtonTypeCustom];
            tmpBackgroundView.backgroundColor = [UIColor darkTextColor];
            tmpBackgroundView.frame = self.superview.bounds;
            [tmpBackgroundView addTarget:self action:@selector(backgroundViewPressed) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(self, &backgroundViewKey, tmpBackgroundView, OBJC_ASSOCIATION_RETAIN);
            backgroundView = tmpBackgroundView;
        }
        // don't animate if dynamically created background view is current superview
        if (backgroundView.superview == nil) {
            // store some info for later
            objc_setAssociatedObject(self, &oldFrameKey, [NSValue valueWithCGRect:self.frame], OBJC_ASSOCIATION_RETAIN);
            objc_setAssociatedObject(self, &oldIndexKey, [NSNumber numberWithInteger:[self.superview.subviews indexOfObject:self]], OBJC_ASSOCIATION_RETAIN);
            
            CGFloat newScale = MIN((self.superview.frame.size.width * 0.75f) / self.frame.size.width, (self.superview.frame.size.height * 0.75f) / self.frame.size.height);
            CGSize newSize = CGSizeMake(newScale * self.frame.size.width, newScale * self.frame.size.height);
            CGRect newFrame = CGRectMake(self.superview.frame.size.width/2 - newSize.width/2, self.superview.frame.size.height/2 - newSize.height/2, newSize.width, newSize.height);
            [self.superview addSubview:backgroundView];
            [self.superview bringSubviewToFront:self];
            backgroundView.alpha = 0.00f;
            
            [UIView beginAnimations:UIViewBasicAnimationFlipToCenterModalYes context:(__bridge void *)(@(toCenter))];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:duration];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self cache:YES];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(flipToCenteredModalDidStop:finished:context:)];
            
            /*self.layer.transform = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate(self.layer.transform, M_PI_2, 0.00f, 1.00f, 0.00f),
                                                                           CATransform3DScale(self.layer.transform, newScale, newScale, 1.00f)),
                                                                           CATransform3DTranslate(self.layer.transform, -(self.center.x - (newFrame.origin.x + newFrame.size.width/2)), -(self.center.y - (newFrame.origin.y + newFrame.size.height/2)), 0));
            */
           
            
            [UIView commitAnimations];
            
            [UIView beginAnimations:nil context:(__bridge void *)(@(toCenter))];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:duration - duration/3.00f];
            [UIView setAnimationDelay:duration/3.00f];

            self.frame = newFrame;
            backgroundView.alpha = 0.50f;
            
            [UIView commitAnimations];
        }
	}
	else {
        NSValue *oldFrameValue = (NSValue *)objc_getAssociatedObject(self, &oldFrameKey);
        if (backgroundView != nil && oldFrameValue != nil) {
            CGRect oldFrame = [oldFrameValue CGRectValue];
            
            [UIView beginAnimations:UIViewBasicAnimationFlipToCenterModalNo context:(__bridge void *)(@(toCenter))];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:duration];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self cache:YES];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(flipToCenteredModalDidStop:finished:context:)];
            
            //self.layer.transform = CATransform3DIdentity;
                        
            [UIView commitAnimations];
            
            [UIView beginAnimations:nil context:(__bridge void *)(@(toCenter))];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:duration - duration/3.00f];
            [UIView setAnimationDelay:duration/3.00f];
            
            self.frame = oldFrame;
            backgroundView.alpha = 0.00f;
            
            [UIView commitAnimations];
        }
	}
}
- (void)flipToCenteredModalDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    BOOL wasToCenter = [(__bridge NSNumber *)context boolValue];
    if (!wasToCenter) {
        UIView *backgroundView = (UIView *)objc_getAssociatedObject(self, &backgroundViewKey);
        NSNumber *oldIndexValue = (NSNumber *)objc_getAssociatedObject(self, &oldIndexKey);
        if (oldIndexValue != nil && backgroundView != nil) {
            UIView *theSuperview = self.superview;
            NSInteger oldIndex = [oldIndexValue integerValue];
            
            [self removeFromSuperview];
            [backgroundView removeFromSuperview];
            [theSuperview insertSubview:self atIndex:oldIndex];
        }
    }
    
    NSObject <UIViewBasicAnimationDelegate> *delegate = (NSObject <UIViewBasicAnimationDelegate> *)objc_getAssociatedObject(self, &lastUsedDelegateKey);

    if (delegate != nil)
        [delegate viewFinishedAnimating:animationID finished:finished theView:self];
}
- (void)backgroundViewPressed {
    NSTimeInterval duration = 0.50f;
    NSNumber *lastUsedDurationValue = (NSNumber *)objc_getAssociatedObject(self, &lastUsedDurationKey);
    if (lastUsedDurationValue != nil) {
        duration = [lastUsedDurationValue floatValue];
    }
    
    [self flipToCenteredModal:NO duration:duration delegate:(NSObject <UIViewBasicAnimationDelegate> *)objc_getAssociatedObject(self, &lastUsedDelegateKey)];
}

@end
