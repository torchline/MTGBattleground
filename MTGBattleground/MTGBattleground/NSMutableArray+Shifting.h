//
//  NSMutableArray+Shifting.h
//  ScramblerFramework
//
//  Created by Brad Walker on 7/20/12.
//  Copyright 2012 Torchline Technology LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (Shifting)

- (void)swapObjectsAtIndex:(NSInteger)firstIndex andIndex:(NSInteger)secondIndex;
- (void)swapIndexesOfObject:(NSObject *)firstObject andObject:(NSObject *)secondObject;
- (void)shiftObjectAtIndex:(NSInteger)firstIndex toIndex:(NSInteger)secondIndex;
- (void)shiftObject:(NSObject *)object toIndex:(NSInteger)index;

- (void)shuffle;

@end
