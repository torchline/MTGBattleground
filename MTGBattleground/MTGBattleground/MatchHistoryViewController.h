//
//  MatchHistoryViewController.h
//  MTGBattleground
//
//  Created by Brad Walker on 5/21/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ManagableViewController.h"

@class ObjectListView;
@class CPTGraphHostingView;
@class CPTGraph;
@class CPTTheme;
@class CPTMutableTextStyle;
@class CPTMutableLineStyle;

@interface MatchHistoryViewController : ManagableViewController {
	NSDateFormatter *_dateFormatter;
	NSMutableArray *_matches;
	NSMutableDictionary *_users;
	NSMutableDictionary *_lifePerTurnPlots;
	
	CPTGraph *_graph;
	CPTTheme *_graphTheme;
	CPTMutableTextStyle *_graphTitleStyle;
	CPTMutableTextStyle *_graphAxisTitleStyle;
	CPTMutableTextStyle *_graphAxisLabelStyle;
	CPTMutableLineStyle *_graphAxisLineStyle;
	CPTMutableLineStyle *_graphAxisTickStyle;
	CPTMutableLineStyle *_graphGridStyle;
	
	IBOutlet ObjectListView *_matchListView;
	IBOutlet CPTGraphHostingView *_graphHostingView;
}

@end
