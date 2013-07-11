//
//  ObjectListItemView.h
//  AbbyCustomTracer
//
//  Created by Brad Walker on 7/1/13.
//  Copyright (c) 2013 Brain Counts. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum : NSUInteger {
	ObjectListItemViewStateNormal,
	ObjectListItemViewStateSelected,
	ObjectListItemViewStateEditing,
	ObjectListItemViewStateEditingSelected
} ObjectListItemViewState;


@protocol ObjectListItemViewDelegate;


@interface ObjectListItemView : UIView {
	UITapGestureRecognizer *_tapGestureRecognizer;
	id _object;
}

@property (nonatomic) id object;
@property (nonatomic) ObjectListItemViewState state;
@property (nonatomic, weak) id<ObjectListItemViewDelegate> delegate;

+ (CGFloat)minimumHeight;
+ (Class)objectClass;
+ (BOOL)isSelectable;

- (void)setState:(ObjectListItemViewState)state animated:(BOOL)animated;

@end



@protocol ObjectListItemViewDelegate <NSObject>

@required
- (void)objectListItemViewTapped:(ObjectListItemView *)objectView;

@end