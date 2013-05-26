//
//  User.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/14/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic) NSString *ID;
@property (nonatomic) NSString *name;
@property (nonatomic) NSUInteger userIconID;
@property (nonatomic) NSUInteger numTimesUsed;
@property (nonatomic) NSDate *lastTimeUsed;

- (User *)initWithID:(NSString *)ID
				name:(NSString *)name
		  userIconID:(NSUInteger)userIconID
		numTimesUsed:(NSUInteger)numTimesUsed
		lastTimeUsed:(NSDate *)lastTimeUsed;

@end
