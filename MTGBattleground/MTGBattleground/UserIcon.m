//
//  UserIcon.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "UserIcon.h"

@implementation UserIcon

@synthesize image = _image;

#pragma mark - Init

- (UserIcon *)initWithID:(NSUInteger)ID
			   imagePath:(NSString *)imagePath {
	
	self = [super init];
	if (self) {
		_ID = ID;
		_imagePath = imagePath;
	}
	return self;
}


#pragma mark - Getter / Setter

- (UIImage *)image {
	if (!_image) {
		_image = [UIImage imageNamed:self.imagePath];
	}
	
	return _image;
}


@end
