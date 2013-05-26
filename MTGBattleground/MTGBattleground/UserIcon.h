//
//  UserIcon.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserIcon : NSObject

@property (nonatomic) NSUInteger ID;
@property (nonatomic) NSString *imagePath;

@property (nonatomic, readonly) UIImage *image;

- (UserIcon *)initWithID:(NSUInteger)ID
			   imagePath:(NSString *)imagePath;

@end
