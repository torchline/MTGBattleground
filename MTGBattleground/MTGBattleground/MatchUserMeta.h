//
//  MatchUserMeta.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/22/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MatchAccess.h"

@interface MatchUserMeta : NSObject

@property (nonatomic) NSString *matchID;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSUInteger turnOrder;
@property (nonatomic) UserPosition userPosition;

- (MatchUserMeta *)initWithMatchID:(NSString *)matchID
							userID:(NSString *)userID
						 turnOrder:(NSUInteger)turnOrder
					  userPosition:(UserPosition)userPosition;

@end
