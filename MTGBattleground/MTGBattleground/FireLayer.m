//
//  FireLayer.m
//  MTGBattleground
//
//  Created by Brad Walker on 6/26/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "FireLayer.h"

@implementation FireLayer


#pragma mark - Init

- (id)init {
	self = [super init];
	if (self) {
		_fireEmitterLayer = [CAEmitterLayer new];
		//_fireEmitterLayer.emitterPosition = CGPointMake(100, 400);
		//_fireEmitterLayer.emitterSize = CGSizeMake(1, 0);
		_fireEmitterLayer.emitterMode = kCAEmitterLayerOutline;
		_fireEmitterLayer.emitterShape = kCAEmitterLayerLine;
		_fireEmitterLayer.renderMode = kCAEmitterLayerAdditive;
		[self addSublayer:_fireEmitterLayer];
		
		_fireCell = [CAEmitterCell new];
		[_fireCell setName:@"fire"];
		_fireCell.emissionLongitude  = M_PI;
		_fireCell.velocity = -80.0f;
		_fireCell.velocityRange = 30.0f;
		_fireCell.emissionRange	= 1.10f;
		_fireCell.yAcceleration	= -200.0f;
		_fireCell.scaleSpeed = 0.30f;
		
		// Add the smoke emitter cell to the smoke emitter layer
		_fireEmitterLayer.emitterCells = @[_fireCell];
		
		self.heat = 0.3f;
		self.fireColor = [UIColor colorWithRed:0.20f green:0.40f blue:0.80f alpha:0.10f];
		self.fireImage = [UIImage imageNamed:@"DazFire"];
	}
	return self;
}

- (id)initWithHeat:(CGFloat)heat fireColor:(UIColor *)fireColor {
	self = [self init];
	if (self) {
		self.heat = heat;
		self.fireColor = fireColor;
	}
	return self;
}


#pragma mark - System

- (void)layoutSublayers {
	_fireEmitterLayer.frame = self.bounds;
}


#pragma mark - Getter / Setter

- (void)setHeat:(CGFloat)heat {
	_heat = heat;
	
	_fireCell.birthRate = heat * 500;
	_fireCell.lifetime = heat;
	_fireCell.lifetimeRange = heat * 0.35f;
	_fireEmitterLayer.emitterSize = CGSizeMake(50 * heat, 0);
}

- (void)setFireColor:(UIColor *)fireColor {
	_fireColor = fireColor;
	
	_fireCell.color = fireColor.CGColor;
}

- (void)setFireImage:(UIImage *)fireImage {
	_fireImage = fireImage;
	
	_fireCell.contents = (__bridge id)fireImage.CGImage;
}

@end
