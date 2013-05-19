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

#pragma mark - Getter / Setter

- (UIImage *)image {
	if (_image) {
		return _image;
	}
	
	_image = [UIImage imageNamed:self.imagePath];
	
	return _image;
}


#pragma mark - Protocol
#pragma mark Identifiable

- (id)identifiableID {
	return @(self.ID);
}

@end
