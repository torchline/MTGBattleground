//
//  ButtonListView.h
//  AbbyPhonics
//
//  Created by Brad Walker on 10/1/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectListItemView.h"

typedef enum {
	ObjectListViewScrollPositionNone,
	ObjectListViewScrollPositionMinimum,
	ObjectListViewScrollPositionBottom,
	ObjectListViewScrollPositionMiddle,
	ObjectListViewScrollPositionTop
} ObjectListViewScrollPosition;


@class ObjectListView;


@protocol ObjectListViewDelegate <UIScrollViewDelegate>

@optional
- (void)objectListView:(ObjectListView *)objectListView didSelectObject:(id)object;

- (void)objectListView:(ObjectListView *)objectListView didEnterInlineEditingModeForObject:(id)object;
- (void)objectListView:(ObjectListView *)objectListView didExitInlineEditingModeForObject:(id)object;

- (void)objectListView:(ObjectListView *)objectListView didSelectObjectForEditing:(id)object;

@end


@class ObjectListItemView;


@interface ObjectListView : UIScrollView {
	BOOL _isSelectingManually;
	BOOL _isSelectingManuallyAnimated;
	BOOL _isEditingInlineAnimated;
	BOOL _isEditingAnimated;
	ObjectListItemViewState _defaultObjectViewState;
	CGFloat _gap;
	CGRect _editingViewVisibleFrame;
	
	Class _viewClass;
	UIColor *_clearColor;
	id _objectToSelectAfterScrollingAnimation;
    NSArray *_objects;
	UIView *_editingView;
	ObjectListItemView *_objectViewToEdit;
	
	NSMutableArray *_visibleObjectViews;
	NSMutableArray *_availableObjectViews;
	NSMutableDictionary *_valuesToSetOnObjectViews;
}

@property (nonatomic, readonly) BOOL isEditing;
@property (nonatomic, readonly) BOOL isEditingInline;
@property (nonatomic) BOOL isZebraStriped;
@property (nonatomic) BOOL isSelectionAnimated;
@property (nonatomic) UIColor *zebraStripeColor;
@property (nonatomic, readonly) id selectedObject;
@property (nonatomic, weak) id<ObjectListViewDelegate> delegate;

- (void)setObjects:(NSArray *)objects
   objectViewClass:(Class)viewClass
			   gap:(NSInteger)gap;

- (void)selectObject:(id)object;
- (void)selectObject:(id)object animated:(BOOL)animated scrollPosition:(ObjectListViewScrollPosition)scrollPosition;

- (void)setValueOnObjectViews:(id)value forKey:(NSString *)key;

- (void)enterEditingModeAnimated:(BOOL)animated;
- (void)exitEditingModeAnimated:(BOOL)animated;

- (void)enterInlineEditingModeForObject:(id)object usingView:(UIView *)editingView animated:(BOOL)animated;
- (void)exitInlineEditingModeAnimated:(BOOL)animated;

@end




