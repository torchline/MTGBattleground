//
//  LifeCounterView.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/11/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LocalUser;

@interface LifeCounterView : UIView

@property (nonatomic) LocalUser *localUser;
@property (nonatomic) BOOL enabled;

@end
