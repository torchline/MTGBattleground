//
//  DynamicCounterView.h
//  MTGBattleground
//
//  Created by Brad Walker on 6/30/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol DynamicCounterViewDelegate;


@interface DynamicCounterView : UIView {
	UITapGestureRecognizer *_tapGestureRecognizer;
	UIPanGestureRecognizer *_panGestureRecognizer;
	UILongPressGestureRecognizer *_longPressGestureRecognizer;
	
	UILabel *_label;
}

@property (nonatomic) NSInteger count;
@property (nonatomic, weak) id<DynamicCounterViewDelegate> delegate;

@end



@protocol DynamicCounterViewDelegate <NSObject>

@required
- (void)dynamicCounterViewDidRequestToBeDeleted:(DynamicCounterView *)dynamicCounterView;

@end