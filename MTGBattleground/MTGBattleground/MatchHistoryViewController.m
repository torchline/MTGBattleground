//
//  MatchHistoryViewController.m
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "MatchHistoryViewController.h"

#import "MatchService.h"
#import "UserService.h"
#import "CorePlot-CocoaTouch.h"

#import "Match+Runtime.h"
#import "MatchTurn+Runtime.h"
#import "User+Runtime.h"
#import "ViewManagerAccess.h"
#import "ObjectListView.h"
#import "MatchHistoryListItemView.h"
#import "UIColor+Pastel.h"


@interface MatchHistoryViewController () <CPTScatterPlotDataSource, CPTBarPlotDataSource, ObjectListViewDelegate>

@property (nonatomic, weak) Match *selectedMatch;

@end



@implementation MatchHistoryViewController

#pragma mark - System

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}


#pragma mark - Init

- (void)viewDidLoad {
	[super viewDidLoad];
	
	_matches = [MatchService matchesWithLimit:10 offset:0];
	NSAssert([_matches count] > 0, @"No matches");
	
	// Match List View
	_matchListView.delegate = self;
	_matchListView.isZebraStriped = YES;
	_matchListView.backgroundColor = [UIColor offWhitePastelColor];
	_matchListView.zebraStripeColor = [UIColor whiteColor];
	[_matchListView setObjects:_matches objectViewClass:[MatchHistoryListItemView class] gap:0];
	
	_users = [UserService userDictionary];
	_lifePerTurnPlots = [[NSMutableDictionary alloc] initWithCapacity:[_matches count]];
	
	[self createGlobalGraphSettings];
	
	Match *firstMatch = _matches[0];
	[_matchListView selectObject:firstMatch];
	self.selectedMatch = firstMatch;
}

- (void)createGlobalGraphSettings {
	// create hosting view for graphs
	//_graphHostingView = [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(400, 100, 600, 600)];
	_graphHostingView.allowPinchScaling = NO;
	[self.view addSubview:_graphHostingView];
	
	// create global graph stuff
	//_graphTheme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	
	// title text style
	_graphTitleStyle = [CPTMutableTextStyle new];
	_graphTitleStyle.color = [CPTColor whiteColor];
	_graphTitleStyle.fontName = @"Thonburi-Bold";
	_graphTitleStyle.fontSize = 24.0f;
	
	// axis text style
	_graphAxisTitleStyle = [CPTMutableTextStyle new];
	_graphAxisTitleStyle.color = _graphTitleStyle.color;
	_graphAxisTitleStyle.fontName = _graphTitleStyle.fontName;
	_graphAxisTitleStyle.fontSize = 20.0f;
	
	// axis label style
	_graphAxisLabelStyle = [CPTMutableTextStyle new];
	_graphAxisLabelStyle.color = _graphAxisTitleStyle.color;
	_graphAxisLabelStyle.fontName = _graphTitleStyle.fontName;
	_graphAxisLabelStyle.fontSize = 15.0f;
	_graphAxisLabelStyle.textAlignment = CPTTextAlignmentCenter;
	
	// axis line style
	_graphAxisLineStyle = [CPTMutableLineStyle new];
	_graphAxisLineStyle.lineWidth = 2.0f;
	_graphAxisLineStyle.lineColor = _graphAxisTitleStyle.color;
	
	// axis tick style
	_graphAxisTickStyle = [CPTMutableLineStyle new];
	_graphAxisTickStyle.lineColor = _graphAxisLineStyle.lineColor;
	_graphAxisTickStyle.lineWidth = 2.0f;
	
	// grid style
	_graphGridStyle = [CPTMutableLineStyle new];
	_graphGridStyle.lineColor = [CPTColor colorWithGenericGray:0.40f];
	_graphGridStyle.lineWidth = 1.0f;
	
	// graph
	_graph = [[CPTXYGraph alloc] initWithFrame:_graphHostingView.bounds];
	//_graph.fill = [CPTFill fillWithGradient:[CPTGradient gradientWithBeginningColor:[CPTColor colorWithGenericGray:0.40f] endingColor:[CPTColor colorWithGenericGray:0.10f]]];
	//[_graph applyTheme:_graphTheme];
	_graph.plotAreaFrame.borderLineStyle = nil;
	
	_graph.titleTextStyle = _graphTitleStyle;
	_graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	_graph.titleDisplacement = CGPointMake(0.0f, 20.0f);
	
	[_graph.plotAreaFrame setPaddingLeft:30.0f];
	[_graph.plotAreaFrame setPaddingBottom:30.0f];
	
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;

	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)_graph.axisSet;
	
	CPTAxis *x = axisSet.xAxis;
	x.titleTextStyle = _graphAxisTitleStyle;
	x.titleOffset = 40.0f;
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
	x.labelTextStyle = _graphAxisLabelStyle;
	x.axisLineStyle = _graphAxisLineStyle;
	x.majorTickLineStyle = _graphAxisLineStyle;
	x.majorTickLength = 16.0f;
	x.majorGridLineStyle = _graphGridStyle;
	x.minorTickAxisLabels = nil;
	x.minorTickLength = 0;
	x.tickDirection = CPTSignNone;
	//x.gridLinesRange = [[CPTPlotRange alloc] initWithLocation:CPTDecimalFromCGFloat(0) length:CPTDecimalFromInteger(INFINITY)];
	x.visibleAxisRange = [[CPTPlotRange alloc] initWithLocation:CPTDecimalFromCGFloat(0) length:CPTDecimalFromInteger(INFINITY)];
	
	CPTAxis *y = axisSet.yAxis;
	y.titleTextStyle = _graphAxisTitleStyle;
	y.titleOffset = 40.0f;
	y.axisLineStyle = _graphAxisLineStyle;
	y.majorTickLineStyle = _graphAxisLineStyle;
	y.majorGridLineStyle = _graphGridStyle;
	y.labelingPolicy = CPTAxisLabelingPolicyNone;
	y.labelTextStyle = _graphAxisLabelStyle;
	y.labelOffset = 16.0f;
	y.majorTickLength = 16.0f;
	y.minorTickAxisLabels = nil;
	y.minorTickLength = 0;
	y.tickDirection = CPTSignNone;
	y.gridLinesRange = [[CPTPlotRange alloc] initWithLocation:CPTDecimalFromCGFloat(0) length:CPTDecimalFromInteger(INFINITY)];
	//y.visibleAxisRange = y.gridLinesRange;
	
	_graphHostingView.hostedGraph = _graph;
}


#pragma mark - User Interaction

- (IBAction)backButtonPressed {
	[[ViewManager sharedInstance] switchToView:[MatchSetupViewController class]];
}

- (IBAction)lifeButtonPressed {
	
}

- (IBAction)damageButtonPressed {
	
}


#pragma mark - Helper

- (void)switchToLifePerTurnGraph {
	_graph.title = [_dateFormatter stringFromDate:_selectedMatch.startTime];
	
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)_graph.axisSet;
	CPTAxis *x = axisSet.xAxis;
	CPTAxis *y = axisSet.yAxis;
	x.title = @"Turn";
	y.title = @"Life";
	
	// AXES
	NSArray *turns = self.selectedMatch.turns;
	NSUInteger turnCount = [turns count];
	NSUInteger turnIncrement = turnCount / 10.;
	NSMutableSet *xLabels = [[NSMutableSet alloc] initWithCapacity:turnCount];
	NSMutableSet *xLocations = [[NSMutableSet alloc] initWithCapacity:turnCount];
	for (int i = 0; i < turnCount; i += turnIncrement) {
		MatchTurn *turn = turns[i];
		
		if (turn.turnNumber == 0) {
			continue;
		}
		
		CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[[NSString alloc] initWithFormat:@"%d", turn.turnNumber] textStyle:x.labelTextStyle];
		CGFloat location = i++;
		label.tickLocation = CPTDecimalFromCGFloat(location);
		label.offset = x.majorTickLength;
		if (label) {
			[xLabels addObject:label];
			[xLocations addObject:@(location)];
		}
	}
	x.axisLabels = xLabels;
	x.majorTickLocations = xLocations;
	
	
	NSMutableArray *lifeNumbers = [[NSMutableArray alloc] initWithCapacity:[turns count]];
	NSInteger highestLife = 0;  // should determine dynamically based on max life
	for (MatchTurn *turn in self.selectedMatch.turns) {
		for (NSNumber *userIDValue in turn.userStateDictionary) {
			MatchTurnUserState *userState = [turn.userStateDictionary objectForKey:userIDValue];
			if (userState.life > highestLife) {
				highestLife = userState.life;
			}
			[lifeNumbers addObject:@(userState.life)];
		}
	}
	CGFloat yMax = highestLife + 2;
	[lifeNumbers sortUsingSelector:@selector(compare:)];
	
	NSMutableSet *yLabels = [[NSMutableSet alloc] initWithCapacity:yMax];
	NSMutableSet *yMajorLocations = [[NSMutableSet alloc] initWithCapacity:yMax];
	
	NSInteger lastLife = NSNotFound;
	for (NSNumber *lifeNumber in lifeNumbers) {
		NSInteger life = [lifeNumber integerValue];
		
		if (lastLife == life - 1 || life == 0) {
			continue;
		}
		
		CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[[NSString alloc] initWithFormat:@"%i", life] textStyle:y.labelTextStyle];
		NSDecimal location = CPTDecimalFromInteger(life);
		label.tickLocation = location;
		label.offset = y.majorTickLength + (life < 10 ? 4 : 0);
		[yLabels addObject:label];
		
		[yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
		
		lastLife = life;
	}
	
	y.axisLabels = yLabels;
	y.majorTickLocations = yMajorLocations;
	
	
	// PLOTS
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
	NSUInteger i = 0;
	
	NSValue *selectedMatchPointerValue = [NSValue valueWithPointer:(__bridge const void *)_selectedMatch];
	
	NSMutableArray *plots = [_lifePerTurnPlots objectForKey:selectedMatchPointerValue];
	if (!plots) {
		plots = [[NSMutableArray alloc] initWithCapacity:[self.selectedMatch.users count]];
		
		for (User *user in self.selectedMatch.users) {
			CPTScatterPlot *plot = [CPTScatterPlot new];
			plot.dataSource = self;
			plot.identifier = user.ID;
			plot.title = user.name;
			
			CPTMutableLineStyle *plotLineStyle = [plot.dataLineStyle mutableCopy];
			CPTColor *plotColor = [self colorForPlotNumber:i];
			plotLineStyle.lineWidth = 4;
			plotLineStyle.lineColor = plotColor;
			plot.dataLineStyle = plotLineStyle;
			
			/*
			 CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle new];
			 symbolLineStyle.lineColor = plotColor;
			 
			 CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
			 symbol.fill = [CPTFill fillWithColor:plotColor];
			 symbol.lineStyle = symbolLineStyle;
			 symbol.size = CGSizeMake(8.0f, 8.0f);
			 */
			plot.plotSymbol = nil;
			
			[plots addObject:plot];
			
			i++;
		}
		
		[_lifePerTurnPlots setObject:plots forKey:selectedMatchPointerValue];
	}
	
	for (CPTPlot *plot in plots) {
		[_graph addPlot:plot toPlotSpace:plotSpace];
	}
	
	// 3 - Set up plot space
	[plotSpace scaleToFitPlots:plots];
	
	CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
	[xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
	plotSpace.xRange = xRange;
	
	CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
	[yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.35f)];
	plotSpace.yRange = yRange;
}

- (CPTColor *)colorForPlotNumber:(NSInteger)number {
	switch (number) {
		case 0:
			return [CPTColor colorWithComponentRed:0.80f green:0.20f blue:0.20f alpha:1];
			break;

		case 1:
			return [CPTColor colorWithComponentRed:0.10f green:0.70f blue:.80f alpha:1];
			break;
			
		case 2:
			return [CPTColor colorWithComponentRed:0.30f green:0.80f blue:0.30f alpha:1];
			break;

		case 3:
			return [CPTColor colorWithComponentRed:1.00f green:0.60f blue:0.20f alpha:1];
			break;
			
		default:
			return [CPTColor whiteColor];
			break;
	}
}


#pragma mark - Delegate

- (void)objectListView:(ObjectListView *)objectListView didSelectObject:(id)object {
	self.selectedMatch = object;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
	return [self.selectedMatch.turns count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			if (index < [self.selectedMatch.turns count]) {
				return @(index);
			}
			break;
			
		case CPTScatterPlotFieldY: {
			MatchTurn *turn = self.selectedMatch.turns[index];
			MatchTurnUserState *userState = [turn.userStateDictionary objectForKey:plot.identifier];
			return @(userState.life);
		}	break;
	}
	return [NSDecimalNumber zero];
}


#pragma mark - Getter / Setter

- (void)setSelectedMatch:(Match *)selectedMatch {	
	// load users for match
	if (!selectedMatch.users) {
		NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:4];
		NSArray *metas = [MatchService matchUserMetasForMatch:selectedMatch];

		for (MatchUserMeta *meta in metas) {
			User *user = [_users objectForKey:meta.userID];
			NSAssert(user, @"Could not find User with ID: %@", meta.userID);
			
			[users addObject:user];
		}
		
		selectedMatch.users = users;
	}
	
	// load turns for match
	if (!selectedMatch.turns) {
		selectedMatch.turns = [MatchService matchTurnsForMatch:selectedMatch];
		
		for (MatchTurn *turn in selectedMatch.turns) {
			if (!turn.userStateDictionary) {
				turn.userStateDictionary = [MatchService matchTurnUserStateDictionaryForMatchTurn:turn];
			}
		}
	}
	
	NSMutableArray *oldPlots = [_lifePerTurnPlots objectForKey:[NSValue valueWithPointer:(__bridge const void *)_selectedMatch]];
	for (CPTPlot *plot in oldPlots) {
		[_graph removePlot:plot];
	}
	
	_selectedMatch = selectedMatch;

	[self switchToLifePerTurnGraph];
}

@end
