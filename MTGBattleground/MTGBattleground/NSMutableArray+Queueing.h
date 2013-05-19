//
//  NSMutableArray+Queueing.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/17/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queueing)

- (id)popRandomObject;
- (id)objectAfterObject:(id)object;

@end
