//
//  UIView+CoreAnimation.m
//  CALayerAnimTest
//
//  Created by Brad Walker on 5/17/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import "UIView+CoreAnimation.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (CoreAnimation)

- (NSString *)animateExpand:(CoreAnimationExpandType)type {
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	anim.duration = 0.125;
    
    switch (type) {
        case CoreAnimationExpandTypeUp:
            anim.autoreverses = NO;
            anim.repeatCount = 0;
            anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.20, 1.20, 1.0)];
            anim.removedOnCompletion = YES;
            break;
            
        case CoreAnimationExpandTypeDown:
            anim.autoreverses = NO;
            anim.repeatCount = 0;
            anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.00, 1.00, 1.0)];
            anim.removedOnCompletion = YES;
            break;
            
        case CoreAnimationExpandTypeUpDown:
            anim.autoreverses = YES;
            anim.repeatCount = 1;
            anim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.20, 1.20, 1.0)];
            anim.removedOnCompletion = YES;
            break;
            
        default:
            break;
    }
    
	[anim setValue:self forKey:@"target"];
	[anim setValue:[NSNumber numberWithInteger:type] forKey:@"type"];
	
	NSString *animationKey = @"Expand";
	[self.layer addAnimation:anim forKey:animationKey];
	
	return animationKey;
}

- (NSString *)animateShake {
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	anim.duration = 0.06f;
	anim.repeatCount = 3;
	anim.autoreverses = YES;
	anim.removedOnCompletion = YES;
	anim.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.frame.origin.x + self.frame.size.width/2 - 3, self.frame.origin.y + self.frame.size.height/2)];
	anim.toValue = [NSValue valueWithCGPoint:CGPointMake(self.frame.origin.x + self.frame.size.width/2 + 3, self.frame.origin.y + self.frame.size.height/2)];
	[anim setValue:self forKey:@"target"];
	
	NSString *animationKey = @"Shake";
	[self.layer addAnimation:anim forKey:animationKey];
	
	return animationKey;}

- (NSString *)animateWiggle {
	CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.values = @[@(-0.03f), @(0.03f)];
    rotationAnimation.duration = 0.14f + ((arc4random() % 100) * .0005f);
    rotationAnimation.autoreverses = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
	[rotationAnimation setValue:self forKey:@"target"];

	CAKeyframeAnimation *translationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    translationAnimation.values = @[@(-1.2f), @(1.2f)];
    translationAnimation.duration = 0.09f + ((arc4random() % 100) * .0005f);
    translationAnimation.autoreverses = YES;
    translationAnimation.repeatCount = HUGE_VALF;
    translationAnimation.additive = YES;
	[translationAnimation setValue:self forKey:@"target"];
	
	CAAnimationGroup *animGroup = [CAAnimationGroup animation];
	animGroup.animations = @[rotationAnimation, translationAnimation];
	[animGroup setValue:self forKey:@"target"];
	
	NSString *animationKey = @"Wiggle";
	[self.layer addAnimation:animGroup forKey:animationKey];
	
	return animationKey;
}

- (NSString *)animateBackAndForthToPoint:(CGPoint)toPoint
						  duration:(CFTimeInterval)duration
							repeatCount:(CGFloat)repeatCount
						completion:(void (^)(BOOL finished))completion {
	
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
	anim.delegate = self;
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	anim.duration = duration;
	anim.repeatCount = repeatCount;
	anim.autoreverses = YES;
	anim.removedOnCompletion = YES;
	anim.fromValue = [NSValue valueWithCGPoint:self.center];
	anim.toValue = [NSValue valueWithCGPoint:toPoint];
	[anim setValue:self forKey:@"target"];
	[anim setValue:completion forKey:@"completion"];
		
	NSString *animationKey = @"BackAndForth";
	[self.layer addAnimation:anim forKey:animationKey];
	
	return animationKey;
}


- (NSString *)animateTossAwayToPoint:(CGPoint)point delegate:(id)delegate {
	UIBezierPath *movePath = [UIBezierPath bezierPath];
	[movePath moveToPoint:self.center];
	[movePath addQuadCurveToPoint:point
					 controlPoint:CGPointMake(point.x, self.center.y)];
	
	CAKeyframeAnimation *moveAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	moveAnim.path = movePath.CGPath;
	moveAnim.removedOnCompletion = YES;
	
	CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.2, 0.2, 1.0)];
	scaleAnim.removedOnCompletion = YES;
	
	CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"alpha"];
	opacityAnim.fromValue = [NSNumber numberWithFloat:1.0];
	opacityAnim.toValue = [NSNumber numberWithFloat:0.1];
	opacityAnim.removedOnCompletion = YES;
	
	CAAnimationGroup *animGroup = [CAAnimationGroup animation];
	animGroup.animations = [NSArray arrayWithObjects:moveAnim, scaleAnim, opacityAnim, nil];
	animGroup.duration = 0.5;
	animGroup.delegate = delegate;
	[animGroup setValue:self forKey:@"target"];
	
	NSString *animationKey = @"TossAway";
	[self.layer addAnimation:animGroup forKey:animationKey];
	
	return animationKey;
}


- (NSString *)animateRepeatingQueueWithImage:(UIImage *)image atHorizontal:(NSInteger)horizontal leftToRight:(BOOL)leftToRight duration:(NSTimeInterval)duration {
	CALayer *imageLayer = [CALayer layer];
	imageLayer.contents = (id)image.CGImage;
	imageLayer.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
	imageLayer.position = CGPointMake(self.bounds.size.width / 2, 0);
	
	[self.layer addSublayer:imageLayer];
	
	CGPoint rightPoint = CGPointMake(self.bounds.size.width + imageLayer.bounds.size.width / 2,
									 imageLayer.position.y);
	CGPoint leftPoint = CGPointMake(imageLayer.bounds.size.width / -2,
									imageLayer.position.y);
	
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
	anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	anim.fromValue = [NSValue valueWithCGPoint:leftToRight ? leftPoint : rightPoint];
	anim.toValue = [NSValue valueWithCGPoint:leftToRight ? rightPoint : leftPoint];
	anim.repeatCount = HUGE_VALF;
	anim.duration = duration;
	
	NSString *animationKey = @"RepeatingQueue";
	[self.layer addAnimation:anim forKey:animationKey];
	
	return animationKey;
}



#pragma mark - Completion

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	void (^completion)(BOOL finished) = [anim valueForKey:@"completion"];
	if (completion) {
		completion(flag);
	}
}

@end
