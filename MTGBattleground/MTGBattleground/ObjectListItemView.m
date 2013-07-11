//
//  ObjectListItemView.m
//  AbbyCustomTracer
//
//  Created by Brad Walker on 7/1/13.
//  Copyright (c) 2013 Brain Counts. All rights reserved.
//

#import "ObjectListItemView.h"


@implementation ObjectListItemView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}


#pragma mark - Public

+ (CGFloat)minimumHeight {
	return 40;
}

+ (Class)objectClass {
	return [NSObject class];
}

+ (BOOL)isSelectable {
	return YES;
}


#pragma mark - User Interaction

- (void)tapGestureRecognized {
	switch (_tapGestureRecognizer.state) {
		case UIGestureRecognizerStateEnded:
			[_delegate objectListItemViewTapped:self];
			break;
			
		default:
			break;
	}
}


#pragma mark - Getter / Setter

- (void)setObject:(id)object {
	Class objectClass = [[self class] objectClass];
	NSAssert(!object || [object isKindOfClass:objectClass], @"Expecting object to be of type %@ but received object: %@", NSStringFromClass(objectClass), object);

	_object = object;
}

- (void)setDelegate:(id<ObjectListItemViewDelegate>)delegate {
	_delegate = delegate;
	
	// only create/keep tap gesture recognizer if delegate is non-nil and this class is selectable
	if (delegate) {
		if ([[self class] isSelectable] && !_tapGestureRecognizer) {
			_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized)];
			[self addGestureRecognizer:_tapGestureRecognizer];
		}
	}
	else {
		if (_tapGestureRecognizer) {
			[self removeGestureRecognizer:_tapGestureRecognizer];
			_tapGestureRecognizer = nil;
		}
	}
}

- (void)setState:(ObjectListItemViewState)state {
	[self setState:state animated:NO];
}

- (void)setState:(ObjectListItemViewState)state animated:(BOOL)animated {
	_state = state;
}

@end
