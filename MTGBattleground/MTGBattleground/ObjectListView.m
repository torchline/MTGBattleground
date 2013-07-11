//
//  ObjectListView.m
//  AbbyPhonics
//
//  Created by Brad Walker on 10/1/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import "ObjectListView.h"
#import <QuartzCore/CALayer.h>
#import <objc/runtime.h>


// Dynamic index property
@interface ObjectListItemView (Runtime)
@property (nonatomic) NSUInteger objectIndex;
@end
@implementation ObjectListItemView (Runtime)
- (void)setObjectIndex:(NSUInteger)objectIndex {
	objc_setAssociatedObject(self, @selector(objectIndex), @(objectIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSUInteger)objectIndex {
	return [objc_getAssociatedObject(self, @selector(objectIndex)) unsignedIntegerValue];
}
@end




@interface ObjectListView () <ObjectListItemViewDelegate, UIScrollViewDelegate>

@end


@implementation ObjectListView

@synthesize delegate = _listViewDelegate;


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup {
	[super setDelegate:self];
	self.clipsToBounds = YES;
	
	_isEditing = NO;
	_isEditingAnimated = YES;
	_isEditingInline = NO;
	_isEditingInlineAnimated = YES;
	_isSelectingManually = NO;
	_isSelectingManuallyAnimated = NO;
	_isZebraStriped = NO;
	_isSelectionAnimated = YES;
	_defaultObjectViewState = ObjectListItemViewStateNormal;
	_zebraStripeColor = [UIColor colorWithWhite:1 alpha:0.20f];
	_clearColor = [UIColor clearColor];
	
	_visibleObjectViews = [[NSMutableArray alloc] initWithCapacity:10];
	_availableObjectViews = [[NSMutableArray alloc] initWithCapacity:3];
}


#pragma mark - Public

- (void)setObjects:(NSArray *)objects
   objectViewClass:(Class)viewClass
			   gap:(NSInteger)gap {
	
	_gap = gap;
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		[objectView removeFromSuperview];
	}
	
	if (viewClass != _viewClass) {
		NSAssert([viewClass isSubclassOfClass:[ObjectListItemView class]], @"Expecting view class to be subclass of 'ObjectListItemView' but received '%@'", NSStringFromClass(viewClass));
		
        [_visibleObjectViews removeAllObjects];
		[_availableObjectViews removeAllObjects];
		
		_viewClass = viewClass;
	}
	else {
		[_availableObjectViews addObjectsFromArray:_visibleObjectViews];
		[_visibleObjectViews removeAllObjects];
	}
	   
	_objects = [objects copy];
    
	if ([objects count] > 0) {
		CGRect lastTheoreticalObjectViewFrame = [self objectViewFrameForIndex:[_objects count] - 1];
		self.contentSize = CGSizeMake(self.frame.size.width - self.contentInset.left - self.contentInset.right,
									  CGRectGetMaxY(lastTheoreticalObjectViewFrame));
		
		[self populateObjectViews];
	}
	else {
		self.contentSize = CGSizeZero;
	}
	
	_isSelectingManually = YES;
	[self setSelectedObject:nil];
	_isSelectingManually = NO;
}

- (void)selectObject:(id)object {
	[self selectObject:object animated:NO scrollPosition:ObjectListViewScrollPositionNone];
}

- (void)selectObject:(id)object animated:(BOOL)animated scrollPosition:(ObjectListViewScrollPosition)scrollPosition {
	CGRect rectToScrollTo = CGRectNull;
	
	_isSelectingManuallyAnimated = animated;
	
	if (object) {
		NSAssert([_objects containsObject:object], @"Object %@ not found in Object list: %@", object, _objects);
		
		NSUInteger objectIndex = [_objects indexOfObject:object];
		CGRect objectViewFrame = [self objectViewFrameForIndex:objectIndex];
		
		switch (scrollPosition) {
			case ObjectListViewScrollPositionNone:
				// nothing
				break;
			case ObjectListViewScrollPositionMinimum:
				rectToScrollTo = objectViewFrame;
				break;
			case ObjectListViewScrollPositionBottom: {
				CGFloat y = MAX(0, objectViewFrame.origin.y - (self.bounds.size.height - objectViewFrame.size.height));
				rectToScrollTo = CGRectMake(objectViewFrame.origin.x,
											y,
											objectViewFrame.size.width,
											self.bounds.size.height);
			}	break;
			case ObjectListViewScrollPositionMiddle: {
				CGFloat y = MAX(0, CGRectGetMidY(objectViewFrame) - self.bounds.size.height/2);
				rectToScrollTo = CGRectMake(objectViewFrame.origin.x,
											y,
											objectViewFrame.size.width,
											self.bounds.size.height);
			}	break;
			case ObjectListViewScrollPositionTop: {
				rectToScrollTo = CGRectMake(objectViewFrame.origin.x,
											objectViewFrame.origin.y,
											objectViewFrame.size.width,
											self.bounds.size.height);
			}	break;
				
			default:
				break;
		}
	}
	
	if (!CGRectIsNull(rectToScrollTo)) {
		if (!animated) {
			_isSelectingManually = YES;
			[self setSelectedObject:object];
			_isSelectingManually = NO;
		}
		else {
			_objectToSelectAfterScrollingAnimation = object;
		}
		
		[self scrollRectToVisible:rectToScrollTo animated:animated];
	}
	else {
		_isSelectingManually = YES;
		[self setSelectedObject:object];
		_isSelectingManually = NO;
	}
}

- (void)setValueOnObjectViews:(id)value forKey:(NSString *)key {
	if (!_valuesToSetOnObjectViews) {
		_valuesToSetOnObjectViews = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	
	[_valuesToSetOnObjectViews setObject:value forKey:key];
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		[objectView setValue:value forKey:key];
	}
	
	for (ObjectListItemView *objectView in _availableObjectViews) {
		[objectView setValue:value forKey:key];
	}
}

- (void)enterEditingModeAnimated:(BOOL)animated {
	_isEditing = YES;
	_isEditingAnimated = animated;
	
	[self setSelectedObject:nil];
	
	[self setAllObjectViewStates:ObjectListItemViewStateEditing animated:animated];
}

- (void)exitEditingModeAnimated:(BOOL)animated {
	_isEditing = NO;
	_isEditingAnimated = animated;
	
	[self setAllObjectViewStates:ObjectListItemViewStateNormal animated:animated];
}

- (void)enterInlineEditingModeForObject:(id)object usingView:(UIView *)editingView animated:(BOOL)animated {
	_objectViewToEdit = nil;
	_editingView = editingView;
	_isEditingInlineAnimated = animated;
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		if ([objectView.object isEqual:object]) {
			_objectViewToEdit = objectView;
			break;
		}
	}
	
	NSAssert(_objectViewToEdit, @"Object to insert editing view with is not currently visible");
	
	if (!CGRectContainsRect(self.bounds, _editingViewVisibleFrame)) {
		[self scrollRectToVisible:_editingViewVisibleFrame animated:animated];
		
		if (!animated) {
			[self animateInEditingView];
		}
	}
	else {
		[self animateInEditingView];
	}
}

- (void)exitInlineEditingModeAnimated:(BOOL)animated {
	_isEditingInlineAnimated = animated;
	
	[self animateOutEditingView];
}


#pragma mark - Helper

- (ObjectListItemView *)newObjectView {
	ObjectListItemView *objectView;
	
	if ([_availableObjectViews count] > 0) {
		objectView = _availableObjectViews[0];
		[_availableObjectViews removeObjectAtIndex:0];
	}
	else {
		objectView = [_viewClass new];
		objectView.delegate = self;
		objectView.state = _defaultObjectViewState;
		
		for (NSString *key in _valuesToSetOnObjectViews) {
			id value = [_valuesToSetOnObjectViews objectForKey:key];
			[objectView setValue:value forKey:key];
		}
	}
	
	return objectView;
}

- (void)setAllObjectViewStates:(ObjectListItemViewState)state animated:(BOOL)animated {
	_defaultObjectViewState = state;
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		[objectView setState:state animated:animated];
	}
	
	for (ObjectListItemView *objectView in _availableObjectViews) {
		[objectView setState:state animated:animated];
	}
}

- (BOOL)isDisplayingObjectForIndex:(NSUInteger)index {
	BOOL isDisplaying = NO;
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		if (objectView.objectIndex == index) {
			isDisplaying = YES;
			break;
		}
	}
	
	return isDisplaying;
}

- (void)zebraStripeObjectView:(ObjectListItemView *)objectView {
	objectView.backgroundColor = objectView.objectIndex % 2 == 0 && _isZebraStriped ? _zebraStripeColor : _clearColor;
}

- (CGRect)objectViewFrameForIndex:(NSUInteger)index {
	CGFloat height = [_viewClass minimumHeight];
	
	return CGRectMake(0,
					  index * (height + _gap),
					  self.bounds.size.width - self.contentInset.left - self.contentInset.right,
					  height);
}

- (void)removeVisibleObjectViewsNotBetweenIndex:(NSUInteger)startingIndex andIndex:(NSUInteger)endingIndex {
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		NSUInteger index = objectView.objectIndex;
		
		if (index < startingIndex || index > endingIndex) {
			[objectView removeFromSuperview];
			[_availableObjectViews addObject:objectView];
		}
	}
	[_visibleObjectViews removeObjectsInArray:_availableObjectViews];
}

- (void)addObjectViewForIndex:(NSUInteger)index {
	ObjectListItemView *objectView = [self newObjectView];
	
	id object = _objects[index];
	
	objectView.object = object;
	objectView.objectIndex = index;
	objectView.frame = [self objectViewFrameForIndex:index];
	
	if ([object isEqual:_selectedObject]) {
		objectView.state = ObjectListItemViewStateSelected;
	}
	
	[self zebraStripeObjectView:objectView];
	
	[_visibleObjectViews addObject:objectView];
	
	[self insertSubview:objectView atIndex:0]; // at index 0 so it does not overlay scroll indicator
}

- (void)populateObjectViews {
	CGFloat objectViewHeight = [_viewClass minimumHeight];
	
	CGRect visibleBounds = self.bounds;
    NSUInteger firstVisibleIndex = MAX(0, floorf(CGRectGetMinY(visibleBounds) / objectViewHeight));
    NSUInteger lastVisibleIndex  = MIN([_objects count] - 1, floorf((CGRectGetMaxY(visibleBounds)-1) / objectViewHeight));
	
	// remove views that are out of bounds
	[self removeVisibleObjectViewsNotBetweenIndex:firstVisibleIndex andIndex:lastVisibleIndex];
	
	// add missing views
	for (NSUInteger index = firstVisibleIndex; index <= lastVisibleIndex; index++) {
		if (![self isDisplayingObjectForIndex:index]) {
			[self addObjectViewForIndex:index];
        }
	}
}

- (void)animateInEditingView {
	// disable any other interaction
	self.scrollEnabled = NO;
	[_visibleObjectViews setValue:@NO forKey:@"userInteractionEnabled"];
	
	CGFloat insertionY = CGRectGetMaxY(_objectViewToEdit.frame);
	_editingViewVisibleFrame = CGRectMake(0,
										  insertionY,
										  self.bounds.size.width,
										  _editingView.frame.size.height);
	
	CGRect editingViewFrame = _editingViewVisibleFrame;
	editingViewFrame.size.height = 0;
	_editingView.frame = editingViewFrame;	
	[self addSubview:_editingView];
	
	// move objectViews that are below to make room for editingView
	NSUInteger objectViewToEditIndex = [_visibleObjectViews indexOfObject:_objectViewToEdit];
	NSAssert(objectViewToEditIndex != NSNotFound, @"Object view to edit not found in visible object views");
	
	[UIView animateWithDuration:_isEditingInlineAnimated ? 0.40f : 0
					 animations:^{
						 // move down
						 for (NSUInteger i = objectViewToEditIndex + 1; i < [_visibleObjectViews count]; i++) {
							 ObjectListItemView *visibleObjectView = _visibleObjectViews[i];
							 visibleObjectView.frame = CGRectOffset(visibleObjectView.frame, 0, _editingViewVisibleFrame.size.height);
						 }
						 
						 // expand
						 _editingView.frame = _editingViewVisibleFrame;
					 }
					 completion:^(BOOL finished) {
						 _isEditing = YES;
						 
						 if ([_listViewDelegate respondsToSelector:@selector(objectListView:didEnterEditingModeForObject:)]) {
							 [_listViewDelegate objectListView:self didEnterInlineEditingModeForObject:_objectViewToEdit.object];
						 }
					 }];
}

- (void)animateOutEditingView {
	// move objectViews that are below to make room for editingView
	NSUInteger objectViewToEditIndex = [_visibleObjectViews indexOfObject:_objectViewToEdit];
	NSAssert(objectViewToEditIndex != NSNotFound, @"Object view to edit not found in visible object views");
	
	[UIView animateWithDuration:_isEditingInlineAnimated ? 0.40f : 0
					 animations:^{
						 // move back up
						 for (NSUInteger i = objectViewToEditIndex + 1; i < [_visibleObjectViews count]; i++) {
							 ObjectListItemView *visibleObjectView = _visibleObjectViews[i];
							 visibleObjectView.frame = CGRectOffset(visibleObjectView.frame, 0, -_editingViewVisibleFrame.size.height);
						 }
						 
						 // shrink
						 CGRect editingViewFrame = _editingView.frame;
						 editingViewFrame.size.height = 0;
						 _editingView.frame = editingViewFrame;
					 }
					 completion:^(BOOL finished) {
						 _isEditing = NO;
						 
						 [_editingView removeFromSuperview];
						 _editingView.frame = _editingViewVisibleFrame;

						 // re-enable all other interactions
						 self.scrollEnabled = YES;
						 [_visibleObjectViews setValue:@YES forKey:@"userInteractionEnabled"];
						 
						 if ([_listViewDelegate respondsToSelector:@selector(objectListView:didExitEditingModeForObject:)]) {
							 [_listViewDelegate objectListView:self didExitInlineEditingModeForObject:_objectViewToEdit.object];
						 }
						 						 
						 _objectViewToEdit = nil;
						 _editingView = nil;
						 _editingViewVisibleFrame = CGRectNull;
					 }];
}


#pragma mark - Protocol

- (NSArray *)tearInViewList {
	return _visibleObjectViews;
}


#pragma mark - Delegate

- (void)objectListItemViewTapped:(ObjectListItemView *)objectView {
	[self setSelectedObject:objectView.object];
}


#pragma mark UIScrollView

// forward UIScrollViewDelegate methods to my delegate "_listViewDelegate"

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self populateObjectViews];
	
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[_listViewDelegate scrollViewDidScroll:scrollView];
	}
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
		[_listViewDelegate scrollViewWillBeginDragging:scrollView];
	}
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
		[_listViewDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
	}
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[_listViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}
}
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	BOOL shouldScrollToTop = YES;
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
		shouldScrollToTop = [_listViewDelegate scrollViewShouldScrollToTop:scrollView];
	}
	return shouldScrollToTop;
}
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
		[_listViewDelegate scrollViewDidScrollToTop:scrollView];
	}
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
		[_listViewDelegate scrollViewWillBeginDecelerating:scrollView];
	}
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[_listViewDelegate scrollViewDidEndDecelerating:scrollView];
	}
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	UIView *view;
	if ([_listViewDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
		view = [_listViewDelegate viewForZoomingInScrollView:scrollView];
	}
	return view;
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
		[_listViewDelegate scrollViewWillBeginZooming:scrollView withView:view];
	}
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
		[_listViewDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
	}
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
		[_listViewDelegate scrollViewDidZoom:scrollView];
	}
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if (_objectToSelectAfterScrollingAnimation) {
		_isSelectingManually = YES;
		[self setSelectedObject:_objectToSelectAfterScrollingAnimation];
		_objectToSelectAfterScrollingAnimation = nil;
		_isSelectingManually = NO;
	}
	else if (_objectViewToEdit) {
		[self animateInEditingView];
	}
	
	if ([_listViewDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
		[_listViewDelegate scrollViewDidEndScrollingAnimation:scrollView];
	}
}


#pragma mark - Getter / Setter

- (void)setSelectedObject:(NSObject *)object {
	if ([_selectedObject isEqual:object]) {
		return;
	}
	
	if (object || _selectedObject) {
		BOOL shouldAnimateSelection = _isSelectionAnimated && (!_isSelectingManually || _isSelectingManuallyAnimated);
		ObjectListItemViewState selectedState = _isEditing ? ObjectListItemViewStateEditingSelected : ObjectListItemViewStateSelected;
		
		// unselect old selected view and select new selected view
		for (ObjectListItemView *objectView in _visibleObjectViews) {
			if ([objectView.object isEqual:_selectedObject]) {
				[objectView setState:_defaultObjectViewState animated:shouldAnimateSelection];
			}
			else if ([objectView.object isEqual:object]) {
				[objectView setState:selectedState animated:shouldAnimateSelection];
			}
		}
	}
		
	_selectedObject = object;
	
	if (!_isSelectingManually && object) {
		if (_isEditing) {
			if ([_listViewDelegate respondsToSelector:@selector(objectListView:didSelectObjectForEditing:)]) {
				[_listViewDelegate objectListView:self didSelectObjectForEditing:object];
			}
		}
		else {
			if ([_listViewDelegate respondsToSelector:@selector(objectListView:didSelectObject:)]) {
				[_listViewDelegate objectListView:self didSelectObject:object];
			}
		}
	}
}

- (void)setIsZebraStriped:(BOOL)isZebraStriped {
	if (_isZebraStriped == isZebraStriped) {
		return;
	}
	
	_isZebraStriped = isZebraStriped;
	
	for (ObjectListItemView *objectView in _visibleObjectViews) {
		[self zebraStripeObjectView:objectView];
	}
}

@end
