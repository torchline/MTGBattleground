//
//  UIView+CoreAnimation.h
//  CALayerAnimTest
//
//  Created by Brad Walker on 5/17/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
	CoreAnimationTypeExpand,
	CoreAnimationTypeShake,
	CoreAnimationTypeTossAway
	
} CoreAnimationType;

typedef enum {
    CoreAnimationExpandTypeUp,
    CoreAnimationExpandTypeDown,
    CoreAnimationExpandTypeUpDown
} CoreAnimationExpandType;


@interface UIView (CoreAnimation)

- (NSString *)animateExpand:(CoreAnimationExpandType)type;

- (NSString *)animateShake;

- (NSString *)animateWiggle;

- (NSString *)animateBackAndForthToPoint:(CGPoint)toPoint
								   duration:(CFTimeInterval)duration
								repeatCount:(CGFloat)repeatCount
								 completion:(void (^)(BOOL finished))completion;

- (NSString *)animateTossAwayToPoint:(CGPoint)point delegate:(id)delegate;

- (NSString *)animateRepeatingQueueWithImage:(UIImage *)image atHorizontal:(NSInteger)horizontal leftToRight:(BOOL)leftToRight duration:(NSTimeInterval)duration;


@end
