//
//  MatchHistoryListItemView.h
//  MTGBattleground
//
//  Created by Brad Walker on 7/7/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ObjectListItemView.h"

@interface MatchHistoryListItemView : ObjectListItemView {
	UIEdgeInsets _padding;
	
	CALayer *_selectedBackgroundLayer;
	UILabel *_label;
}

@end
