//
//  FlickrManager.m
//  FlickrTest
//
//  Created by Brad Walker on 5/29/13.
//  Copyright (c) 2013 Torchline Technology. All rights reserved.
//

#import "Flickr.h"
#import "AFNetworking.h"

@implementation Flickr

//static NSURLRequest *_publicPhotoURLRequest = nil;
+ (void)requestPublicPhotosWithCompletion:(void (^)(NSDictionary *response))completion failure:(void (^)())failure {
	/*
	if (!_publicPhotoURLRequest) {
		_publicPhotoURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"]];
	}
	*/
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"]];

	AFJSONRequestOperation __block *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		if (completion) {
			completion(json);
		}
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"Flickr request failed!: %@", [error localizedDescription]);

		if (failure) {
			failure();
		}
	}];
	
	[operation setJSONReadingOptions:NSJSONReadingAllowFragments];
	
	[operation start];
}

@end
