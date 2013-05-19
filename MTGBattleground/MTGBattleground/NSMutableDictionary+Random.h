//
//  NSMutableDictionary+Random.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/18/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Random)

- (id <NSCopying>)randomKey;
- (id)randomObject;

@end
