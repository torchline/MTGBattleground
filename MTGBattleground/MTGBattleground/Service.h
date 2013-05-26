//
//  Service.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/23/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface Service : NSObject

+ (FMDatabaseQueue *)fmDatabaseQueue;
+ (dispatch_queue_t)backgroundQueue;
+ (NSString *)newGUID;

@end
