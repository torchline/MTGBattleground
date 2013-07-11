//
//  FireLayer.h
//  MTGBattleground
//
//  Created by Brad Walker on 6/26/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface FireLayer : CALayer {
	CAEmitterCell *_fireCell;
	CAEmitterLayer *_fireEmitterLayer;
}

@property (nonatomic) CGFloat heat;
@property (nonatomic) UIColor *fireColor;
@property (nonatomic) UIImage *fireImage;

- (id)initWithHeat:(CGFloat)heat fireColor:(UIColor *)fireColor;

@end
