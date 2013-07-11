//
//  FlickrManager.h
//  FlickrTest
//
//  Created by Brad Walker on 5/29/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Flickr : UIView

+ (void)requestPublicPhotosWithCompletion:(void (^)(NSDictionary *response))completion failure:(void (^)())failure;

@end
