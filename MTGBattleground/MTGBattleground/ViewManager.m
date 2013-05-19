//
//  ViewManager.m
//  AcademicsBoard
//
//  Created by Brad Walker on 9/10/12.
//  Copyright (c) 2012 Brain Counts. All rights reserved.
//

#import "ViewManager.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "AccessoryViewController.h"

#define MAX_HISTORY_COUNT		20


@interface ClassValue : NSObject {
	Class class;
}
@property (nonatomic, assign) Class class;
- (id)initWithClass:(Class)aClass;
@end
@implementation ClassValue
@synthesize class;
- (id)initWithClass:(Class)aClass {
	self = [super init];
	if (self) {
		self.class = aClass;
	}
	return self;
}
@end



@interface ViewManager ()

- (void)animateAccessoryOverlayFadeIn:(BOOL)fadeIn duration:(NSTimeInterval)duration;

- (void)setCurrentViewController:(UIViewController *)aViewController;
- (void)openAccessoryViewDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)closeAccessoryViewDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end



@implementation ViewManager

@synthesize currentViewController;
@synthesize currentAccessoryViewController;

#pragma mark - Memory

- (void)dealloc {
	previousViewControllerClasses = nil;
	accessoryViewControllerCache = nil;
	overlayButton = nil;
	currentAccessoryViewController = nil;
}


#pragma mark - Init

static ViewManager *sharedHelper = nil;
+ (ViewManager *)sharedInstance {
	if (sharedHelper == nil) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		sharedHelper = [[self alloc] initWithRootView:appDelegate.window];
	}
	return sharedHelper;
}

- (id)init {
	self = [super init];
	if (self) {		
		previousViewControllerClasses = [[NSMutableArray alloc] initWithCapacity:10];
        nextAccessoryViewControllerClass = nil;
        currentViewController = nil;
		currentAccessoryViewController = nil;
	}
	return self;
}

- (id)initWithRootView:(UIView *)aRootView {
    self = [self init];
    if (self) {
        rootView = aRootView;
    }
    return self;
}


#pragma mark - Public

- (void)animateAccessoryOverlayFadeIn:(BOOL)fadeIn duration:(NSTimeInterval)duration {
    if (overlayButton == nil) {
        overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        overlayButton.alpha = 0.00f;
        overlayButton.backgroundColor = [UIColor blackColor];
        [overlayButton addTarget:self action:@selector(overlayButtonPressed) forControlEvents:UIControlEventTouchDown];
    }
    
    if (overlayButton.superview == nil) {
        [rootView insertSubview:overlayButton aboveSubview:currentViewController.view];
    }
    
    overlayButton.frame = rootView.bounds;
    
    overlayButton.hidden = NO;
	overlayButton.enabled = NO;
	
	[UIView beginAnimations:nil context:(__bridge void *)([NSNumber numberWithBool:fadeIn])];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animateAccessoryOverlayFadeInDidStop:finished:context:)];
	
	overlayButton.alpha = fadeIn ? 0.50f : 0.00f;
	
	[UIView commitAnimations];
}

- (void)animateAccessoryOverlayFadeInDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {	
	BOOL didFadeIn = [(__bridge NSNumber *)context boolValue];
	if (didFadeIn) {
		overlayButton.enabled = YES;
	}
	else {        
		overlayButton.hidden = YES;
        [overlayButton removeFromSuperview];
	}
}

- (void)switchToView:(Class)viewControllerClass {
	[self switchToView:viewControllerClass options:nil];
}

- (void)switchToView:(Class)viewControllerClass options:(NSDictionary *)options {
	NSAssert([viewControllerClass isSubclassOfClass:[ManagableViewController class]], @"Cannot switch to a ViewController that is not a subclass of ManagableViewController");
	
	NSMutableDictionary *mOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	
	[mOptions setValue:[NSNumber numberWithBool:NO] forKey:ViewOptionWasResurrected];
	
    // create next view controller
	nextViewController = [[viewControllerClass alloc] initWithNibName:nil bundle:nil];
    nextViewController.viewOptions = options;
    nextViewController.transitionAnimationDelegate = self;
    //nextViewController.view.frame = rootView.bounds;
	NSLog(@"VM bounds = %@", NSStringFromCGRect(rootView.bounds));
	
	/*
    CGPoint viewStartPoint;
	switch (nextViewController.presentationStyle) {
		case ManagableViewPresentationStyleNone:
		case ManagableViewPresentationStyleFadeIn:
			viewStartPoint = CGPointMake(0, 0);
			break;
		case ManagableViewPresentationStyleSlideFromTop:
		case ManagableViewPresentationStylePushFromTop:
			viewStartPoint = CGPointMake(0, -CGRectGetHeight(rootView.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromRight:
		case ManagableViewPresentationStylePushFromRight:
			viewStartPoint = CGPointMake(CGRectGetMaxX(rootView.bounds), 0);
			break;
		case ManagableViewPresentationStyleSlideFromBottom:
		case ManagableViewPresentationStylePushFromBottom:
			viewStartPoint = CGPointMake(0, CGRectGetMaxY(rootView.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromLeft:
		case ManagableViewPresentationStylePushFromLeft:
			viewStartPoint = CGPointMake(-CGRectGetWidth(currentAccessoryViewController.view.bounds), 0);
			break;
			
		default:
			break;
	}
	
	nextViewController.view.frame = CGRectMake(viewStartPoint.x,
											   viewStartPoint.y,
											   rootView.bounds.size.width,
											   rootView.bounds.size.height);
	
	currentViewController.view.userInteractionEnabled = NO;
	nextViewController.view.userInteractionEnabled = NO;
	
	[nextViewController willPresent];
	 */
	
	if (currentViewController != nil) {
        // history
		lastViewControllerClass = currentViewController.class;

		ClassValue *previousClassValue = [[ClassValue alloc] initWithClass:currentViewController.class];
		[previousViewControllerClasses addObject:previousClassValue];
        
        // delete old history
        if ([previousViewControllerClasses count] > MAX_HISTORY_COUNT) {
            [previousViewControllerClasses removeObjectAtIndex:0];
        }
        
        // allow current view controller to perform any necessary exit animations
        BOOL isDoneUnloading = [currentViewController viewWillUnloadToViewController:nextViewController];
        
        if (isDoneUnloading) {
            [self managableViewControllerDidFinishUnloading:currentViewController];
        }
	}
    else {
        [self setCurrentViewController:nextViewController];
                
        nextViewController = nil;
        
        BOOL isDoneLoading = [currentViewController viewDidLoadFromViewController:nil];
        
        if (isDoneLoading) {
            [self managableViewControllerDidFinishLoading:currentViewController];
        }
    }
}

- (void)switchToPreviousView {
	[self switchToPreviousViewWithOptions:nil];
}

- (void)switchToPreviousViewWithOptions:(NSDictionary *)options {
	NSMutableDictionary *mOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	
	[mOptions setValue:[NSNumber numberWithBool:YES] forKey:ViewOptionWasResurrected];
	
	Class previousViewControllerClass = [self previousViewControllerClass];
	
	// skip same view if it's in history
	while (previousViewControllerClass == currentViewController.class) {
		[previousViewControllerClasses removeLastObject];
		previousViewControllerClass = [self previousViewControllerClass];
	}
	
	nextViewController = [[previousViewControllerClass alloc] initWithNibName:nil bundle:nil];
    //nextViewController.view.frame = rootView.bounds;
    nextViewController.transitionAnimationDelegate = self;
	nextViewController.viewOptions = options;
	
    
    // remove current view from history
    [previousViewControllerClasses removeLastObject];
    
    if (currentViewController != nil) {
		lastViewControllerClass = currentViewController.class;
        
        // allow current view controller to perform any necessary exit animations
        BOOL isDoneUnloading = [currentViewController viewWillUnloadToViewController:nextViewController];
        
        if (isDoneUnloading) {
            [self managableViewControllerDidFinishUnloading:currentViewController];
        }
	}
    else {
        [self setCurrentViewController:nextViewController];
        
        nextViewController = nil;
        
        BOOL isDoneLoading = [currentViewController viewDidLoadFromViewController:nil];
        
        if (isDoneLoading) {
            [self managableViewControllerDidFinishLoading:currentViewController];
        }
    }
}

- (void)openAccessoryViewWithClass:(Class)accessoryViewControllerClass {
	if (currentAccessoryViewController != nil) {
		if (nextAccessoryViewControllerClass == nil) {
			nextAccessoryViewControllerClass = accessoryViewControllerClass;
			
			[self closeAccessoryView];
		}
		
		return;
	}
	
	if (accessoryViewControllerCache == nil) {
		accessoryViewControllerCache = [[NSMutableDictionary alloc] initWithCapacity:5];
	}
	
	currentAccessoryViewController = [accessoryViewControllerCache objectForKey:[NSValue valueWithPointer:(__bridge const void *)(accessoryViewControllerClass)]];
	
	BOOL isFreshlyCreated = NO;
	if (currentAccessoryViewController == nil) {
		AccessoryViewController *newAccessoryViewController = [[accessoryViewControllerClass alloc] init];
		
		[accessoryViewControllerCache setObject:newAccessoryViewController forKey:[NSValue valueWithPointer:(__bridge const void *)(accessoryViewControllerClass)]];
		currentAccessoryViewController = newAccessoryViewController;
		
		
		isFreshlyCreated = YES;
	}
	
	CGPoint accessoryViewStartPoint;
	switch (currentAccessoryViewController.presentationStyle) {
		case ManagableViewPresentationStyleNone:
		case ManagableViewPresentationStyleFadeIn:
			accessoryViewStartPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
												  CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromTop:
		case ManagableViewPresentationStylePushFromTop:
			accessoryViewStartPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
												  CGRectGetMinY(rootView.bounds) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromRight:
		case ManagableViewPresentationStylePushFromRight:
			accessoryViewStartPoint = CGPointMake(CGRectGetMaxX(rootView.bounds),
												  CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromBottom:
		case ManagableViewPresentationStylePushFromBottom:
			accessoryViewStartPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
												  CGRectGetMaxY(rootView.bounds));
			break;
		case ManagableViewPresentationStyleSlideFromLeft:
		case ManagableViewPresentationStylePushFromLeft:
			accessoryViewStartPoint = CGPointMake(CGRectGetMinX(rootView.bounds) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
												  CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
			break;
			
		default:
			break;
	}
	
	if (isFreshlyCreated) {
		[currentAccessoryViewController viewDidLoadFromViewController:currentViewController];
	}
	
	currentAccessoryViewController.view.frame = CGRectMake(accessoryViewStartPoint.x,
												   accessoryViewStartPoint.y,
												   currentAccessoryViewController.view.frame.size.width,
												   currentAccessoryViewController.view.frame.size.height);
    
	if (currentAccessoryViewController.view.superview == nil) {
        [rootView addSubview:currentAccessoryViewController.view];
    }
	
	currentViewController.view.userInteractionEnabled = NO;
	currentAccessoryViewController.view.userInteractionEnabled = NO;
    currentAccessoryViewController.view.hidden = NO;
	
	[currentAccessoryViewController willShow];
	
	switch (currentAccessoryViewController.presentationStyle) {
		case ManagableViewPresentationStyleNone:
			[self openAccessoryViewDidStop:nil finished:nil context:nil];
			return;
			break;
			
		default: {
			CGPoint currentViewEndPoint = currentViewController.view.frame.origin;
			CGPoint accessoryViewEndPoint = currentAccessoryViewController.view.frame.origin;
			CGFloat alpha = currentAccessoryViewController.view.alpha;
			
			switch (currentAccessoryViewController.presentationStyle) {
				case ManagableViewPresentationStyleFadeIn:
					currentAccessoryViewController.view.alpha = 0.00f;
					alpha = 1.00f;
					break;
					
				case ManagableViewPresentationStylePushFromTop:
					currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.bounds),
													  CGRectGetMinY(currentViewController.view.bounds) + CGRectGetHeight(currentAccessoryViewController.view.bounds));
					
					accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
														CGRectGetMinY(rootView.bounds));
					break;
				case ManagableViewPresentationStylePushFromRight:
					currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.bounds) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
													  CGRectGetMinY(currentViewController.view.bounds));
					
					accessoryViewEndPoint = CGPointMake(CGRectGetMaxX(rootView.bounds) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
														CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
					break;
				case ManagableViewPresentationStylePushFromBottom:
					currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.bounds),
													  CGRectGetMinY(currentViewController.view.bounds) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
					
					accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
														CGRectGetMaxY(rootView.bounds) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
					break;
				case ManagableViewPresentationStylePushFromLeft:
					currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.bounds) + CGRectGetWidth(currentAccessoryViewController.view.bounds),
													  CGRectGetMinY(currentViewController.view.bounds));
					
					accessoryViewEndPoint = CGPointMake(CGRectGetMinX(rootView.bounds),
														CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
					break;
					
				case ManagableViewPresentationStyleSlideFromTop:
				case ManagableViewPresentationStyleSlideFromRight:
				case ManagableViewPresentationStyleSlideFromBottom:
				case ManagableViewPresentationStyleSlideFromLeft:
					accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
														CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
					break;
					
				default:
					break;
			}
			
			isAnimatingAccessoryView = YES;
			
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDuration:0.30f];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(openAccessoryViewDidStop:finished:context:)];
			
			if (!CGPointEqualToPoint(currentViewEndPoint, currentViewController.view.frame.origin)) {
				currentViewController.view.frame = CGRectMake(currentViewEndPoint.x,
															  currentViewEndPoint.y,
															  currentViewController.view.frame.size.width,
															  currentViewController.view.frame.size.height);
			}
			
			if (!CGPointEqualToPoint(accessoryViewEndPoint, currentAccessoryViewController.view.frame.origin)) {
				currentAccessoryViewController.view.frame = CGRectMake(accessoryViewEndPoint.x,
															   accessoryViewEndPoint.y,
															   currentAccessoryViewController.view.frame.size.width,
															   currentAccessoryViewController.view.frame.size.height);
			}
			
			if (alpha != currentAccessoryViewController.view.alpha) {
				currentAccessoryViewController.view.alpha = alpha;
			}
			
			[UIView commitAnimations];
			
			switch (currentAccessoryViewController.presentationStyle) {
				case ManagableViewPresentationStyleFadeIn:
					break;
					
				default:
					[self animateAccessoryOverlayFadeIn:YES duration:0.30f];
					break;
			}
		}	break;
	}
}
- (void)openAccessoryViewDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	currentAccessoryViewController.view.userInteractionEnabled = YES;

    [currentAccessoryViewController didShow];
	
	isAnimatingAccessoryView = NO;
}

- (void)closeAccessoryView {
	if (currentAccessoryViewController == nil) {
		return;
	}
	
	currentViewController.view.userInteractionEnabled = NO;
	currentAccessoryViewController.view.userInteractionEnabled = NO;

	[currentAccessoryViewController willHide];
	
	CGPoint currentViewEndPoint = currentViewController.view.frame.origin;
	CGPoint accessoryViewEndPoint = currentAccessoryViewController.view.frame.origin;
	CGFloat alpha = currentAccessoryViewController.view.alpha;
	
	switch (currentAccessoryViewController.presentationStyle) {
		case ManagableViewPresentationStylePushFromTop:
			currentViewEndPoint = CGPointMake(currentViewController.view.frame.origin.x,
											  CGRectGetMinY(currentViewController.view.frame) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
			
			accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
												CGRectGetMinY(rootView.bounds) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
			break;
		case ManagableViewPresentationStylePushFromRight:
			currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.frame) + CGRectGetWidth(currentAccessoryViewController.view.bounds),
											  currentViewController.view.frame.origin.y);

			accessoryViewEndPoint = CGPointMake(CGRectGetMaxX(rootView.bounds),
												CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
			break;
		case ManagableViewPresentationStylePushFromBottom:
			currentViewEndPoint = CGPointMake(currentViewController.view.frame.origin.x,
											  CGRectGetMinY(currentViewController.view.frame) + CGRectGetHeight(currentViewController.view.bounds));
			
			accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
												CGRectGetMaxY(rootView.bounds));
			break;
		case ManagableViewPresentationStylePushFromLeft:
			currentViewEndPoint = CGPointMake(CGRectGetMinX(currentViewController.view.frame) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
											  currentViewController.view.frame.origin.y);
			
			accessoryViewEndPoint = CGPointMake(CGRectGetMinX(rootView.bounds) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
												CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
			break;
		default: {
			switch (currentAccessoryViewController.dismissionStyle) {
				case ManagableViewDismissionStyleNone:
					[self animateAccessoryOverlayFadeIn:NO duration:0.00f];
					[self closeAccessoryViewDidStop:nil finished:nil context:nil];
					return;
					break;
					
				default: {
					switch (currentAccessoryViewController.dismissionStyle) {
						case ManagableViewDismissionStyleFadeOut:
							alpha = 0.00f;
							break;
							
						case ManagableViewDismissionStyleSlideToTop:
							accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
																CGRectGetMinY(rootView.bounds) - CGRectGetHeight(currentAccessoryViewController.view.bounds));
							break;
						case ManagableViewDismissionStyleSlideToRight:
							accessoryViewEndPoint = CGPointMake(CGRectGetMaxX(rootView.bounds),
																CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
							break;
						case ManagableViewDismissionStyleSlideToBottom:
							accessoryViewEndPoint = CGPointMake(CGRectGetMidX(rootView.bounds) - CGRectGetMidX(currentAccessoryViewController.view.bounds),
																CGRectGetMaxY(rootView.bounds));
							break;
						case ManagableViewDismissionStyleSlideToLeft:
							accessoryViewEndPoint = CGPointMake(CGRectGetMinX(rootView.bounds) - CGRectGetWidth(currentAccessoryViewController.view.bounds),
																CGRectGetMidY(rootView.bounds) - CGRectGetMidY(currentAccessoryViewController.view.bounds));
							break;
							
						default:
							break;
					}
				}	break;
			}
		}	break;
	}
	
	isAnimatingAccessoryView = YES;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.30f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(closeAccessoryViewDidStop:finished:context:)];
	
	if (!CGPointEqualToPoint(currentViewEndPoint, currentViewController.view.frame.origin)) {
		currentViewController.view.frame = CGRectMake(currentViewEndPoint.x,
													  currentViewEndPoint.y,
													  currentViewController.view.frame.size.width,
													  currentViewController.view.frame.size.height);
	}
	
	if (!CGPointEqualToPoint(accessoryViewEndPoint, currentAccessoryViewController.view.frame.origin)) {
		currentAccessoryViewController.view.frame = CGRectMake(accessoryViewEndPoint.x,
													   accessoryViewEndPoint.y,
													   currentAccessoryViewController.view.frame.size.width,
													   currentAccessoryViewController.view.frame.size.height);
	}
	
	if (currentAccessoryViewController.view.alpha != alpha) {
		currentAccessoryViewController.view.alpha = alpha;
	}
	
	[UIView commitAnimations];
	
	switch (currentAccessoryViewController.presentationStyle) {
		case ManagableViewPresentationStylePushFromTop:
		case ManagableViewPresentationStylePushFromRight:
		case ManagableViewPresentationStylePushFromBottom:
		case ManagableViewPresentationStylePushFromLeft: {
			if (nextAccessoryViewControllerClass == nil) {
				[self animateAccessoryOverlayFadeIn:NO duration:0.30f];
			}
		}	break;
			
		default: {
			switch (currentAccessoryViewController.dismissionStyle) {
				case ManagableViewDismissionStyleFadeOut:
					break;
					
				default:
					if (nextAccessoryViewControllerClass == nil) {
						[self animateAccessoryOverlayFadeIn:NO duration:0.30f];
					}
					break;
			}
		}	break;
	}
}
- (void)closeAccessoryViewDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[currentAccessoryViewController.view removeFromSuperview];
	[currentAccessoryViewController didHide];
	currentAccessoryViewController = nil;
	
	if (nextAccessoryViewControllerClass != nil) {		
		[self openAccessoryViewWithClass:nextAccessoryViewControllerClass];
		nextAccessoryViewControllerClass = nil;
	}
	else {
		currentViewController.view.userInteractionEnabled = YES;
	}
	
	isAnimatingAccessoryView = NO;
}


#pragma mark - User Interaction

- (void)overlayButtonPressed {
	if (!isAnimatingAccessoryView) {
		[self closeAccessoryView];
	}
}


#pragma mark - Delegate

- (void)managableViewControllerDidFinishLoading:(ManagableViewController *)aViewController {
    if ([aViewController isEqual:currentViewController]) {
        // next controller is finished animating in so release previously retained controller
        lastViewController = nil;
    }
}

- (void)managableViewControllerDidFinishUnloading:(ManagableViewController *)aViewController {
    if ([aViewController isEqual:currentViewController]) {
        // retain so next controller can access it for purposes of customized loading (animation, etc.)
        lastViewController = currentViewController;
        
        [self setCurrentViewController:nextViewController];
        
        nextViewController = nil;
        
        BOOL isDoneLoading = [currentViewController viewDidLoadFromViewController:lastViewController];
        
        if (isDoneLoading) {
            [self managableViewControllerDidFinishLoading:currentViewController];
        }
    }
}


#pragma mark - Getter/Setter

- (void)setCurrentViewController:(ManagableViewController *)aViewController {
	if (currentViewController != nil) {		
		if (currentViewController.view.superview != nil) {
			[currentViewController.view removeFromSuperview];
		}
		
		currentViewController = nil;
	}
	
	if (aViewController != nil) {		
		currentViewController = aViewController;
		
		if ([rootView isKindOfClass:[UIWindow class]]) {
			[(UIWindow *)rootView setRootViewController:currentViewController];
		}
		else {
			[rootView insertSubview:currentViewController.view atIndex:0];
		}
	}
}

- (Class)previousViewControllerClass {
	return [(ClassValue *)[previousViewControllerClasses lastObject] class];
}


@end
