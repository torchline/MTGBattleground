//
//  UserListItemView.h
//  MTGBattleground
//
//  Created by Brad Walker on 7/3/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "ObjectListItemView.h"

@interface UserListItemView : ObjectListItemView {
	UIEdgeInsets _padding;
	
	CALayer *_selectedBackgroundLayer;
	UILabel *_label;
	UIButton *_deleteButton;
}

@end
